import Foundation

public struct BotTTSText: Codable {
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
}
