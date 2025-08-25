import Foundation

public struct BotReadyData: Codable {

    public let version: String
    public let about: Value?

    public init(version: String, about: Value?) {
        self.version = version
        self.about = about
    }
}
