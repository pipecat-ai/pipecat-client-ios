import Foundation

public struct BotLLMText: Codable {
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
}
