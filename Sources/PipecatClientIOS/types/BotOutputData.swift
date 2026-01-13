import Foundation

public struct BotOutputData: Codable {
    public enum AggregationType: String, Codable {
        case word
        case sentence
    }

    public let aggregatedBy: AggregationType
    public let text: String
    public let spoken: Bool

    enum CodingKeys: String, CodingKey {
        case text
        case spoken
        case aggregatedBy = "aggregated_by"
    }

    public init(text: String, spoken: Bool, aggregatedBy: AggregationType) {
        self.text = text
        self.spoken = spoken
        self.aggregatedBy = aggregatedBy
    }
}
