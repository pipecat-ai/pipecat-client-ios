import Foundation

public struct LLMFunctionCallData: Codable {
    public let functionName: String
    public let toolCallID: String
    public let args: Value

    enum CodingKeys: String, CodingKey {
        case functionName = "function_name"
        case toolCallID = "tool_call_id"
        case args
    }

    public init(functionName: String, toolCallID: String, args: Value) {
        self.functionName = functionName
        self.toolCallID = toolCallID
        self.args = args
    }
}

public typealias FunctionCallCallback = (LLMFunctionCallData, @escaping (Value) async -> Void) async -> Void
