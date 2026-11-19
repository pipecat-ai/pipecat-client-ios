import Foundation

/// An RTVI control message received the by the Transport.
public struct RTVIMessageInbound: Codable {

    public let id: String?
    public let label: String?
    public let type: String?
    public let data: String?

    /// Messages from the server to the client.
    public enum MessageType {
        /// Bot is connected and ready to receive messages
        public static let BOT_READY = "bot-ready"

        /// Server response to client message
        public static let SERVER_RESPONSE = "server-response"

        /// Received an error response from the server
        public static let ERROR_RESPONSE = "error-response"

        /// Received an error from the server
        public static let ERROR = "error"

        /// STT transcript (both local and remote) flagged with partial final or sentence
        public static let TRANSCRIPT = "transcript"

        /// STT transcript from the user
        public static let USER_TRANSCRIPTION = "user-transcription"

        /// STT transcript from the bot
        public static let BOT_TRANSCRIPTION = "bot-transcription"

        /// User started speaking
        public static let USER_STARTED_SPEAKING = "user-started-speaking"

        // User stopped speaking
        public static let USER_STOPPED_SPEAKING = "user-stopped-speaking"

        // Bot started speaking
        public static let BOT_STARTED_SPEAKING = "bot-started-speaking"

        // Bot stopped speaking
        public static let BOT_STOPPED_SPEAKING = "bot-stopped-speaking"

        /// Pipecat metrics
        public static let METRICS = "metrics"

        /// LLM transcript from the bot
        public static let BOT_LLM_TEXT = "bot-llm-text"
        /// LLM transcript from the bot has started
        public static let BOT_LLM_STARTED = "bot-llm-started"
        /// LLM transcript from the bot has stopped
        public static let BOT_LLM_STOPPED = "bot-llm-stopped"

        /// TTS transcript from the bot
        public static let BOT_TTS_TEXT = "bot-tts-text"
        /// LLM transcript from the bot has started
        public static let BOT_TTS_STARTED = "bot-tts-started"
        /// LLM transcript from the bot has stopped
        public static let BOT_TTS_STOPPED = "bot-tts-stopped"

        /// Server message
        public static let SERVER_MESSAGE = "server-message"

        /// The LLM started calling a function.
        public static let LLM_FUNCTION_CALL_STARTED = "llm-function-call-started"

        /// The LLM is calling a function, with as much about the call as the bot reports.
        public static let LLM_FUNCTION_CALL_IN_PROGRESS = "llm-function-call-in-progress"

        /// A function call finished, or was cancelled.
        public static let LLM_FUNCTION_CALL_STOPPED = "llm-function-call-stopped"

        /// The LLM is calling a function. Deprecated: bots send `LLM_FUNCTION_CALL_IN_PROGRESS` instead.
        public static let LLM_FUNCTION_CALL = "llm-function-call"

        /// Context
        public static let APPEND_TO_CONTEXT_RESULT = "append-to-context-result"

        // Bot LLM search response
        public static let BOT_LLM_SEARCH_RESPONSE = "bot-llm-search-response"

        // All bot output along with metadata like if it's spoken
        public static let BOT_OUTPUT = "bot-output"

        /// The bot was interrupted and stopped what it was saying.
        public static let BOT_INTERRUPTED = "bot-interrupted"

        /// The bot stopped listening to the user.
        public static let USER_MUTE_STARTED = "user-mute-started"

        /// The bot listens to the user again.
        public static let USER_MUTE_STOPPED = "user-mute-stopped"

        /// What the user said or typed.
        public static let USER_INPUT = "user-input"

        /// The user's message as the bot's LLM receives it.
        public static let USER_LLM_TEXT = "user-llm-text"

        /// Voice activity detection heard the user start speaking.
        public static let VAD_USER_STARTED_SPEAKING = "vad-user-started-speaking"

        /// Voice activity detection heard the user stop speaking.
        public static let VAD_USER_STOPPED_SPEAKING = "vad-user-stopped-speaking"

        /// How loud the user's audio is, as the bot measures it.
        public static let USER_AUDIO_LEVEL = "user-audio-level"

        /// How loud the bot's audio is, as the bot measures it.
        public static let BOT_AUDIO_LEVEL = "bot-audio-level"

        /// A line of the bot's log.
        public static let SYSTEM_LOG = "system-log"

        /// The marker the bot's LLM put in a response.
        public static let BOT_LLM_MARKER = "bot-llm-marker"

        /// A transcription as the bot's STT produces it.
        public static let STT_RAW_TEXT = "stt-raw-text"

        /// Text as the bot's LLM streams it.
        public static let LLM_RAW_TEXT = "llm-raw-text"

        /// Text the bot's TTS speaks, as it speaks it.
        public static let TTS_RAW_TEXT = "tts-raw-text"
    }

    public init(type: String?, data: String?) {
        self.init(type: type, data: data, id: String(UUID().uuidString.prefix(8)), label: "rtvi-ai")
    }

    public init(type: String?, data: String?, id: String?, label: String? = "rtvi-ai") {
        self.id = id
        self.label = label
        self.type = type
        self.data = data
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case label
        case type
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(String.self, forKey: .type)

        let datavalue = try? container.decodeIfPresent(Value.self, forKey: .data)
        let data: String?
        if datavalue != nil {
            data = try? String(data: JSONEncoder().encode(datavalue), encoding: .utf8)
        } else {
            data = nil
        }

        let label = try? container.decodeIfPresent(String.self, forKey: .label)
        let id = try? container.decodeIfPresent(String.self, forKey: .id)

        self.init(type: type, data: data, id: id, label: label)
    }

    public static func errorMessage(error: String, fatal: Bool = false) -> RTVIMessageInbound {
        return RTVIMessageInbound(
            type: RTVIMessageInbound.MessageType.ERROR,
            data: BotError(error: error, fatal: fatal).asString
        )
    }
}
