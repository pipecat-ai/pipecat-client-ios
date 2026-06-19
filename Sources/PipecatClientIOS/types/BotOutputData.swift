import Foundation

/// Protocol 2.0.0: Tracks TTS spoken progress for a segment word-by-word.
public struct BotOutputProgressData: Codable {
    public let accumulatedText: String
    public let remainingText: String

    enum CodingKeys: String, CodingKey {
        case accumulatedText = "accumulated_text"
        case remainingText = "remaining_text"
    }
}

public struct BotOutputData: Codable {
    public enum AggregationType: String, Codable {
        case word
        case sentence
    }

    /// Protocol 2.0.0: Lifecycle stage of a spoken segment.
    public enum SpokenStatus: String, Codable {
        case new = "new"
        case inProgress = "in-progress"
        case completed = "completed"
    }

    public let aggregatedBy: AggregationType
    public let text: String

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
    public let segmentId: String?

    enum CodingKeys: String, CodingKey {
        case text
        case _spoken = "spoken"
        case aggregatedBy = "aggregated_by"
        case willBeSpoken = "will_be_spoken"
        case spokenStatus = "spoken_status"
        case spokenProgress = "spoken_progress"
        case segmentId = "segment_id"
    }

    public init(
        text: String,
        spoken: Bool? = nil,
        aggregatedBy: AggregationType,
        willBeSpoken: Bool? = nil,
        spokenStatus: SpokenStatus? = nil,
        spokenProgress: BotOutputProgressData? = nil,
        segmentId: String? = nil
    ) {
        self.text = text
        self._spoken = spoken
        self.aggregatedBy = aggregatedBy
        self.willBeSpoken = willBeSpoken
        self.spokenStatus = spokenStatus
        self.spokenProgress = spokenProgress
        self.segmentId = segmentId
    }
}
