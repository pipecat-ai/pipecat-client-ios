import Foundation

/// A sound or pause the bot performed in expressive conversation (alpha, RTVI 2.3.0+), reported as it was
/// performed.
public enum BotExpressionData: Equatable {
    /// A sound, such as `"laugh"`, by Pipecat's universal name for it, the same whichever TTS service performs it.
    case sound(String)
    /// A pause, of a number of milliseconds.
    case pause(durationMs: Int)

    /// The expression a bot output reports, if it reports one.
    init?(output: BotOutputData) {
        switch output.outputType {
        case .expressionSound:
            self = .sound(output.text)
        case .expressionPause:
            guard let durationMs = Int(output.text) else {
                return nil
            }
            self = .pause(durationMs: durationMs)
        default:
            return nil
        }
    }
}

/// The bot's delivery changed, in expressive conversation (alpha, RTVI 2.3.0+). Reported only when it changes:
/// a stressed word brings `"emphasis"` and the word after it takes it away again.
public struct BotDeliveryUpdatedData: Equatable {
    /// The delivery of the words the bot is speaking now, such as `["warm"]`; empty for the voice's baseline, and
    /// `nil` once it stops speaking.
    public let delivery: [String]?
    /// The delivery before the change, or `nil` when it wasn't speaking.
    public let previous: [String]?

    public init(delivery: [String]?, previous: [String]?) {
        self.delivery = delivery
        self.previous = previous
    }
}
