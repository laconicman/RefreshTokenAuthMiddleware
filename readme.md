# RefreshTokenAuthMiddleware

[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Flaconicman%2FRefreshTokenAuthMiddleware%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/laconicman/RefreshTokenAuthMiddleware)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Flaconicman%2FRefreshTokenAuthMiddleware%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/laconicman/RefreshTokenAuthMiddleware)

An auth middleware package for [Swift OpenAPI Generator/Runtime](https://github.com/apple/swift-openapi-generator) for a common scenario dealing with long-living refresh token and short-living access token.
The library is quite universal in and can cover most of such cases.

## Features

- 📝 Clear and compact
- ⚡️ Prevents duplication of auth queries
- 🔧 Flexible and configurable
- 🎯 Fires only when it sees that token is missing, invalid or expired

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/laconicman/RefreshTokenAuthMiddleware.git", from: "1.0.0")
]
```

Then add the dependency to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "RefreshTokenAuthMiddleware", package: "RefreshTokenAuthMiddleware")
        ]
    )
]
```

## Usage

### For "Client" generated with Swift OpenAPI Generator, implement conformance to "SignInAndRefresh" protocol.
This will define the logic of specific authentication queries, their results, and token validation.

``` swift
import Foundation
import HTTPTypes // Gonna need this to modify requests inside those funcs of `SignInAndRefresh` protocol.

extension Client: SignInAndRefresh {
    typealias Token = String
    typealias RefreshToken = String
    func signIn(credentials: Credentials) async throws -> (accesToken: Token, refreshToken: RefreshToken) {
        // adjust to your API operation
        let response = try await authSignIn(body: .json(.init(login: credentials.username, pwd: credentials.password))) 
        let auth = try response.ok.body.applicationJsonCharsetUtf8.auth
        return (auth.token, auth.refreshToken)
    }
    // This could be (and should be?) @Sendable too
    func refreshTokenIfNeeded(with refreshToken: RefreshToken?) async throws -> Token {
        guard let refreshToken else { throw NSError(domain: "", code: 0, userInfo: nil) }
        //        if Date().timeIntervalSince1970 >= expirationDate {
        // adjust to your API operation
        let refreshTokenResponse = try await authRefreshToken(body: .json(.init(token: refreshToken)))
        return try refreshTokenResponse.ok.body.applicationJsonCharsetUtf8.auth.token
    }
    
    @Sendable func authorizeRequest(_ request: HTTPRequest, with accessToken: Token?) throws -> HTTPRequest {
       // Setup request according to the doc. Usually just a header.
        var authorizedRequest = request
        authorizedRequest.headerFields[.authorization] = "Bearer \(try validatedAndFormattedAccessToken(accessToken))"
        return authorizedRequest
    }
    @Sendable func validatedAndFormattedAccessToken(_ token: Token?) throws -> Token {
        // if Date().timeIntervalSince1970 >= expirationDate {
        guard let token else { throw NSError(domain: "", code: 0, userInfo: nil)}
        return token
    }

}
```

### Pass `RefreshTokenAuthMiddleware` to your generated `Client`
In `main` it could look like this:

```swift
import OpenAPIRuntime
import OpenAPIURLSession
import Foundation

struct OuterClient: Sendable {
    let client: Client
    private let refreshTokenAuthMiddleware: RefreshTokenAuthMiddleware<Client>
    // private var auth: Components.Schemas.Auth?
    init?(credentials: Credentials) {
        guard let serverURL = try? Servers.Server1.url() else { return nil}
        let authManagementClient = Client(
            serverURL: serverURL,
            transport: URLSessionTransport()
        )
        refreshTokenAuthMiddleware = RefreshTokenAuthMiddleware(authManagementClient: authManagementClient, credentials: credentials)
        self.client = Client(
            serverURL: serverURL,
            transport: URLSessionTransport(),
            middlewares: [refreshTokenAuthMiddleware]
        )
    }
}

let client = OuterClient(credentials: .init())
// Authorization is fully automatic by now. But if we do sign in there should be no extra re-auth request.
// let authorizationResponse = try await client?.client.signIn(credentials: .init())
// print(authorizationResponse ?? "No auth response")
let adminUsersResponse = try await client?.listGoods(body: .json(.init(limit: 10, offset: 0, page: 1, filter: "", order: .init(id: "asc"))))
print(adminUsersResponse ?? "No admin users response")
```

## Contributing

Contributions and are welcome!

## This is a helper package for the following 

- [swift-openapi-generator](https://github.com/apple/swift-openapi-generator) - The main Swift OpenAPI Generator project
- [swift-openapi-runtime](https://github.com/apple/swift-openapi-runtime) - Runtime library for Swift OpenAPI Generator

## License

This project is licensed under the Apache License 2.0.
