import Foundation

struct Credentials: Sendable {
    let username: String
    let password: String
}

extension Credentials {
    init() {
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
