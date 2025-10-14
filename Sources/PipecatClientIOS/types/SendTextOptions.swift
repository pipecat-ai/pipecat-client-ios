import Foundation

public struct SendTextOptions: Codable {
    public let runImmediately: Bool?
    public let audioResponse: Bool?

    enum CodingKeys: String, CodingKey {
        case audioResponse = "audio_response"
        case runImmediately = "run_immediately"
    }

    public init(runImmediately: Bool? = true, audioResponse: Bool? = false) {
        self.runImmediately = runImmediately
        self.audioResponse = audioResponse
    }
}
