import OpenAPIRuntime
import HTTPTypes

public protocol SignInAndRefresh: Sendable {
    associatedtype Credentials: Sendable
    associatedtype Token: Sendable
    associatedtype RefreshToken: Sendable
    func signIn(credentials: Credentials) async throws -> (accesToken: Token, refreshToken: RefreshToken)
    func refreshTokenIfNeeded(with refreshToken: RefreshToken?) async throws -> Token
    @Sendable func authorizeRequest(_ request: HTTPRequest, with accessToken: Token?) throws -> HTTPRequest
    @Sendable func validatedAndFormattedAccessToken(_ token: Token?) throws -> Token
}
