import Foundation

public struct LLMFunctionCallResult: Codable {
    let functionName: String
    let toolCallID: String
    let arguments: Value
    let result: Value

    enum CodingKeys: String, CodingKey {
        case functionName = "function_name"
        case toolCallID = "tool_call_id"
        case arguments
        case result
    }
}
