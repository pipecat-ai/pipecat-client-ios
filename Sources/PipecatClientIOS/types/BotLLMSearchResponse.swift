import Foundation

/// Search entry point from bot LLM search response
public struct SearchEntryPoint: Codable {
    public let renderedContent: String?
    
    enum CodingKeys: String, CodingKey {
        case renderedContent = "rendered_content"
    }
    
    public init(renderedContent: String?) {
        self.renderedContent = renderedContent
    }
}

/// Web source information from bot LLM search response
public struct WebSource: Codable {
    public let uri: String?
    public let title: String?
    
    public init(uri: String?, title: String?) {
        self.uri = uri
        self.title = title
    }
}

/// Grounding chunk information
public struct GroundingChunk: Codable {
    public let web: WebSource?
    
    public init(web: WebSource?) {
        self.web = web
    }
}

/// Grounding segment information
public struct GroundingSegment: Codable {
    public let partIndex: Int?
    public let startIndex: Int?
    public let endIndex: Int?
    public let text: String?
    
    enum CodingKeys: String, CodingKey {
        case partIndex = "part_index"
        case startIndex = "start_index"
        case endIndex = "end_index"
        case text
    }
    
    public init(partIndex: Int?, startIndex: Int?, endIndex: Int?, text: String?) {
        self.partIndex = partIndex
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.text = text
    }
}

/// Grounding support information
public struct GroundingSupport: Codable {
    public let segment: GroundingSegment?
    public let groundingChunkIndices: [Int]?
    public let confidenceScores: [Double]?
    
    enum CodingKeys: String, CodingKey {
        case segment
        case groundingChunkIndices = "grounding_chunk_indices"
        case confidenceScores = "confidence_scores"
    }
    
    public init(segment: GroundingSegment?, groundingChunkIndices: [Int]?, confidenceScores: [Double]?) {
        self.segment = segment
        self.groundingChunkIndices = groundingChunkIndices
        self.confidenceScores = confidenceScores
    }
}

/// Bot LLM search response data structure received from the backend
public struct BotLLMSearchResponseData: Codable {
    public let searchEntryPoint: SearchEntryPoint?
    public let groundingChunks: [GroundingChunk]?
    public let groundingSupports: [GroundingSupport]?
    public let webSearchQueries: [String]?
    
    enum CodingKeys: String, CodingKey {
        case searchEntryPoint = "search_entry_point"
        case groundingChunks = "grounding_chunks"
        case groundingSupports = "grounding_supports"
        case webSearchQueries = "web_search_queries"
    }
    
    public init(searchEntryPoint: SearchEntryPoint?, groundingChunks: [GroundingChunk]?, groundingSupports: [GroundingSupport]?, webSearchQueries: [String]?) {
        self.searchEntryPoint = searchEntryPoint
        self.groundingChunks = groundingChunks
        self.groundingSupports = groundingSupports
        self.webSearchQueries = webSearchQueries
    }
}

// Legacy alias for backward compatibility
public typealias GroundingMetadata = BotLLMSearchResponseData 