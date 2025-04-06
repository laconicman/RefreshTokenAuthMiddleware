import Foundation
import OpenAPIRuntime
import HTTPTypes

// Ensures that only one signIn or refresh operation is held at a time.
// See: https://www.donnywals.com/building-a-token-refresh-flow-with-async-await-and-swift-concurrency/
// There is also totally different approach with recreating `Client` before each request.
// See: https://github.com/luomein/authenticate-any-api
// TODO: We have double assignments for `accessToken` and `refreshToken` in couple of places.
// Consider unifying. Ether only update state and use state, either update state at upper levels only.

actor RefreshTokenAuthMiddleware<C: SignInAndRefresh>: ClientMiddleware {
    private let authManagementClient: C // A client for the same OpenAPI spec, but with no auth middleware
    private let credentials: C.Credentials
    private var accessToken: C.Token?
    private var refreshToken: C.RefreshToken?
    
    private var signInTask: Task<(C.Token, C.RefreshToken), Error>?
    private var refreshTask: Task<C.Token, Error>?
    // We could init with auth logic instead of demanding it in conformance.
    // private let authorizeRequest: (HTTPRequest, C.Token) throws -> HTTPRequest
    // But we need use `authManagementClient` anyway, to make auth requests, so such coupling looks fine.
    
    init(authManagementClient: C, credentials: C.Credentials) {
        self.authManagementClient = authManagementClient
        self.credentials = credentials
    }

    private func refreshTokenIfNeeded() async throws -> C.Token {
        if let signInTask {
            refreshTask = nil // `.cancel()` does not fit here. It does not nilify the var.
            // Besides, `.cancel()` will only work for tasks that support cancelation.
            return try await signInTask.value.0
        }
        if let refreshTask {
            return try await refreshTask.value
        }
        guard refreshToken != nil else { // We should NOT try to sign in here again, should we?
            throw AuthError.missingRefreshToken
        }
        return try await refreshToken()
    }

    private func refreshToken() async throws -> C.Token {
        if let refreshTask {
            return try await refreshTask.value
        }
        let task = Task { () throws -> C.Token in
            defer { refreshTask = nil }
            // let tokenExpiresAt = Date().addingTimeInterval(10)
            let newAccessToken = try await authManagementClient.refreshTokenIfNeeded(with: refreshToken)
            accessToken = newAccessToken
            return newAccessToken
        }
        self.refreshTask = task
        return try await task.value
    }
    
    private func signIn() async throws -> (C.Token, C.RefreshToken) {
        refreshTask = nil
        if let signInTask {
            return try await signInTask.value
        }
        let task = Task { () throws -> (C.Token, C.RefreshToken) in
            defer { signInTask = nil }
            let (newAccessToken, newRefreshToken) = try await authManagementClient.signIn(credentials: credentials)
            (accessToken, refreshToken) = (newAccessToken, newRefreshToken)
            return (newAccessToken, newRefreshToken)
        }
        self.signInTask = task
        return try await task.value
    }
    
    /// Intercepts an outgoing HTTP request and an incoming HTTP response.
    /// - Parameters:
    ///   - request: An HTTP request.
    ///   - body: An HTTP request body.
    ///   - baseURL: A server base URL.
    ///   - operationID: The identifier of the OpenAPI operation.
    ///   - next: A closure that calls the next middleware, or the transport.
    /// - Returns: An HTTP response and its body.
    /// - Throws: An error if interception of the request and response fails.
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        // TODO: Check token validity (date, expiration)
        if accessToken == nil /* && authToken.isValid */ {
            (accessToken, refreshToken) = try await signIn()
        }

        var modifiedRequest = try authManagementClient.authorizeRequest(request, with: accessToken)
        
        // Try the request with the current token
        let (response, responseBody) = try await next(modifiedRequest, body, baseURL)
        
        if response.status == .unauthorized {
            do {
                // Recreate the request body if needed
                // let newBody = body.rewind()
                
                accessToken = try await refreshTokenIfNeeded() // try await authManagementClient.refreshTokenIfNeeded(with: refreshToken)
                
                modifiedRequest = try authManagementClient.authorizeRequest(request, with: accessToken)
                // Retry the request with the new token
                let (response, responseBody) = try await next(modifiedRequest, body, baseURL)
                return (response, responseBody)
            } catch {
                // If token refresh fails, propagate the error
                throw error
            }
        }
        // Return the original response if no refresh was needed
        return (response, responseBody)
    }
    
}

extension RefreshTokenAuthMiddleware {
    enum AuthError: LocalizedError {
        case missingRefreshToken
        var errorDescription: String? {
            switch self {
                case .missingRefreshToken: String(localized: "Missing refresh token. Please try to login again.", comment: "RefreshTokenAuthMiddleware.AuthError")
            }
        }
    }
}
