import Foundation

/// An RTVI control message sent to the Transport.
public struct RTVIMessageOutbound: Encodable {

    public static let RTVI_PROTOCOL_VERSION = "1.0.0"
    public static let RTVI_MESSAGE_LABEL = "rtvi-ai"

    public let id: String
    public let label: String
    public let type: String
    public let data: Value?

    /// Messages from the client to the server.
    public enum MessageType {
        public static let CLIENT_READY = "client-ready"
        public static let DISCONNECT_BOT = "disconnect-bot"
        public static let CLIENT_MESSAGE = "client-message"
        public static let APPEND_TO_CONTEXT = "append-to-context"
        public static let LLM_FUNCTION_CALL_RESULT = "llm-function-call-result"
    }

    public init(
        id: String = String(UUID().uuidString.prefix(8)),
        label: String = RTVI_MESSAGE_LABEL,
        type: String,
        data: Value? = nil
    ) {
        self.id = id
        self.label = label
        self.type = type
        self.data = data
    }

    public static func clientReady() -> RTVIMessageOutbound {
        let data = Value.object([
            "version": .string(RTVI_PROTOCOL_VERSION),
            "about": .object([
                "library": .string(PipecatClient.library),
                "library_version": .string(PipecatClient.libraryVersion)
            ]),
        ])
        return RTVIMessageOutbound(
            type: RTVIMessageOutbound.MessageType.CLIENT_READY,
            data: data
        )
    }

    public static func disconnectBot() -> RTVIMessageOutbound {
        return RTVIMessageOutbound(
            type: RTVIMessageOutbound.MessageType.DISCONNECT_BOT
        )
    }

    public static func clientMessage(msgType: String, data: Value? = nil) -> RTVIMessageOutbound {
        let data = Value.object(["t": .string(msgType), "d": data])
        return RTVIMessageOutbound(
            type: RTVIMessageOutbound.MessageType.CLIENT_MESSAGE,
            data: data
        )
    }

    public static func appendToContext(msg: LLMContextMessage) throws -> RTVIMessageOutbound {
        return RTVIMessageOutbound(
            type: RTVIMessageOutbound.MessageType.APPEND_TO_CONTEXT,
            data: try msg.convertToRtviValue()
        )
    }

}
