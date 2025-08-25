import Foundation

public struct LLMContextMessage: Codable {
    public enum Role: String, Codable {
        case user
        case assistant
    }

    public let role: Role
    public let content: String
    public let runImmediately: Bool?

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case runImmediately = "run_immediately"
    }

    public init(role: Role, content: String, runImmediately: Bool? = false) {
        self.role = role
        self.content = content
        self.runImmediately = runImmediately
    }
}
