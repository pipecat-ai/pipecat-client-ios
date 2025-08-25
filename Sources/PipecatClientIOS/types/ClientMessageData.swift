import Foundation

public struct ClientMessageData: Codable {

    public let t: String
    public let d: Value?

    public init(t: String, d: Value?) {
        self.t = t
        self.d = d
    }
}
