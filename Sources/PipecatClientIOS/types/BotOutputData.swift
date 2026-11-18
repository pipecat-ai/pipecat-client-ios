import Foundation

/// Protocol 2.0.0: Tracks TTS spoken progress for a segment word-by-word.
public typealias BotOutputProgressData = SpokenProgressData

public struct BotOutputData: Codable, Equatable {
    @available(*, deprecated, renamed: "BotOutputType")
    public typealias AggregationType = BotOutputType

    /// Protocol 2.0.0: Lifecycle stage of a spoken segment.
    public struct SpokenStatus: RawRepresentable, Codable, Hashable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let new = SpokenStatus(rawValue: "new")
        public static let inProgress = SpokenStatus(rawValue: "in-progress")
        public static let completed = SpokenStatus(rawValue: "completed")
    }

    public let text: String

    /// What form the text is in, such as `.sentence`, `.word`, or a type of the bot's own, such as `"code"`.
    /// Bots older than protocol 2.3.0 send it as `aggregated_by`, which fills it in.
    public let outputType: BotOutputType

    private let _aggregatedBy: BotOutputType

    /// Deprecated (Protocol 2.3.0). Use `outputType` instead, which it's always the same as.
    @available(*, deprecated, message: "Use outputType instead. This field will be removed in a future version.")
    public var aggregatedBy: BotOutputType { _aggregatedBy }

    private let _spoken: Bool?

    /// Deprecated (Protocol 1.4.x). Use `willBeSpoken` instead.
    @available(*, deprecated, message: "Use willBeSpoken instead. This field will be removed in a future version.")
    public var spoken: Bool? { _spoken }

    /// Protocol 2.0.0: Whether this text will be spoken by TTS.
    public let willBeSpoken: Bool?

    /// Protocol 2.0.0: Current lifecycle stage of the spoken segment.
    public let spokenStatus: SpokenStatus?

    /// Protocol 2.0.0: Word-level progress through the spoken segment.
    public let spokenProgress: BotOutputProgressData?

    /// Protocol 2.0.0: Correlates progress events for the same spoken segment.
    public let segmentId: Int?

    /// Protocol 2.3.0: The delivery of the text just spoken, by its universal names, such as
    /// `["warm", "emphasis"]`, empty for the voice's baseline. Present in expressive conversation (alpha).
    public let delivery: [String]?

    enum CodingKeys: String, CodingKey {
        case text
        case outputType = "output_type"
        case _aggregatedBy = "aggregated_by"
        case _spoken = "spoken"
        case willBeSpoken = "will_be_spoken"
        case spokenStatus = "spoken_status"
        case spokenProgress = "spoken_progress"
        case segmentId = "segment_id"
        case delivery
    }

    /// The deprecated `text_type`, which bots send with the same value as `output_type`.
    private enum DeprecatedCodingKeys: String, CodingKey {
        case textType = "text_type"
    }

    public init(
        text: String,
        outputType: BotOutputType,
        willBeSpoken: Bool? = nil,
        spokenStatus: SpokenStatus? = nil,
        spokenProgress: BotOutputProgressData? = nil,
        segmentId: Int? = nil,
        delivery: [String]? = nil
    ) {
        self.text = text
        self.outputType = outputType
        self._aggregatedBy = outputType
        self._spoken = nil
        self.willBeSpoken = willBeSpoken
        self.spokenStatus = spokenStatus
        self.spokenProgress = spokenProgress
        self.segmentId = segmentId
        self.delivery = delivery
    }

    @available(
        *,
        deprecated,
        message: "Use init(text:outputType:) instead. This initializer will be removed in a future version."
    )
    public init(
        text: String,
        spoken: Bool? = nil,
        aggregatedBy: BotOutputType,
        willBeSpoken: Bool? = nil,
        spokenStatus: SpokenStatus? = nil,
        spokenProgress: BotOutputProgressData? = nil,
        segmentId: Int? = nil
    ) {
        self.text = text
        self.outputType = aggregatedBy
        self._aggregatedBy = aggregatedBy
        self._spoken = spoken
        self.willBeSpoken = willBeSpoken
        self.spokenStatus = spokenStatus
        self.spokenProgress = spokenProgress
        self.segmentId = segmentId
        self.delivery = nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let deprecated = try decoder.container(keyedBy: DeprecatedCodingKeys.self)
        let outputType: BotOutputType
        if let value = try container.decodeIfPresent(BotOutputType.self, forKey: .outputType) {
            outputType = value
        } else if let value = try deprecated.decodeIfPresent(BotOutputType.self, forKey: .textType) {
            outputType = value
        } else {
            outputType = try container.decode(BotOutputType.self, forKey: ._aggregatedBy)
        }
        self.text = try container.decode(String.self, forKey: .text)
        self.outputType = outputType
        self._aggregatedBy = try container.decodeIfPresent(BotOutputType.self, forKey: ._aggregatedBy) ?? outputType
        self._spoken = try container.decodeIfPresent(Bool.self, forKey: ._spoken)
        self.willBeSpoken = try container.decodeIfPresent(Bool.self, forKey: .willBeSpoken)
        self.spokenStatus = try container.decodeIfPresent(SpokenStatus.self, forKey: .spokenStatus)
        self.spokenProgress = try container.decodeIfPresent(BotOutputProgressData.self, forKey: .spokenProgress)
        self.segmentId = try container.decodeIfPresent(Int.self, forKey: .segmentId)
        self.delivery = try container.decodeIfPresent([String].self, forKey: .delivery)
    }
}
