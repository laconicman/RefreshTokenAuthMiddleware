// This is just a boilerplate for implementing
// `Credentials` that can be picked from environment.
// Also good for debugging. Environment settings can be set `.gitignore`-d, so they won't leak.
/*
import Foundation

public struct Credentials: Sendable {
    let username: String
    let password: String
}

extension Credentials {
    public init() {
        guard let username = ProcessInfo.processInfo.environment["APP_USERNAME"] else {
            fatalError("APP_USERNAME environment variable is not set. You can set with `Edit sheme`.")
        }
        guard let password = ProcessInfo.processInfo.environment["APP_PASSWORD"] else {
            fatalError("APP_PASSWORD environment variable is not set. You can set with `Edit sheme`.")
        }
        self.username = username
        self.password = password
    }
}
*/
