import XCTest
@testable import PipecatClientIOS

@MainActor
final class FunctionCallTests: ClientTestCase {
    private var handled: [LLMFunctionCallData] = []

    override func setUp() async throws {
        try await super.setUp()
        handled = []
        client.registerFunctionCallHandler(functionName: "get_weather") { [unowned self] data, onResult in
            self.handled.append(data)
            await onResult(.object(["sunny": .boolean(true)]))
        }
    }

    private var results: [JSON] {
        transport.sent.filter { $0.type == "llm-function-call-result" }.compactMap { try? JSON(encoding: $0)["data"] }
    }

    func testAHandlerAnswersACallInProgress() async throws {
        try await receive(
            "llm-function-call-in-progress",
            data: .object([
                "tool_call_id": "call_1", "function_name": "get_weather", "arguments": .object(["city": "Lisbon"]),
            ])
        )
        try await waitForSent(count: 1)
        XCTAssertEqual(handled.map(\.toolCallID), ["call_1"])
        XCTAssertEqual(
            results,
            [
                .object([
                    "function_name": "get_weather", "tool_call_id": "call_1",
                    "arguments": .object(["city": "Lisbon"]), "result": .object(["sunny": .bool(true)]),
                ])
            ]
        )
    }

    func testNoHandlerRunsForACallWithoutItsArguments() async throws {
        try await receive(
            "llm-function-call-in-progress",
            data: .object(["tool_call_id": "call_1", "function_name": "get_weather"])
        )
        XCTAssertEqual(handled.count, 0)
        XCTAssertEqual(results, [])
        XCTAssertEqual(delegate.calls.map(\.name), ["onLLMFunctionCallInProgress"])
    }

    func testACallReportedWithBothMessagesIsAnsweredOnce() async throws {
        try await receive(
            "llm-function-call-in-progress",
            data: .object([
                "tool_call_id": "call_1", "function_name": "get_weather", "arguments": .object(["city": "Lisbon"]),
            ])
        )
        try await receive(
            "llm-function-call",
            data: .object([
                "function_name": "get_weather", "tool_call_id": "call_1", "args": .object(["city": "Lisbon"]),
            ])
        )
        try await waitForSent(count: 1)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(handled.map(\.toolCallID), ["call_1"])
        XCTAssertEqual(results.count, 1)
    }

    func testACallAfterADisconnectIsAnsweredAgain() async throws {
        let call: JSON = .object([
            "tool_call_id": "call_1", "function_name": "get_weather", "arguments": .object(["city": "Lisbon"]),
        ])
        try await receive("llm-function-call-in-progress", data: call)
        try await waitForSent(count: 1)
        try await client.disconnect()
        try await receive("llm-function-call-in-progress", data: call)
        try await waitForSent(count: 2)
        XCTAssertEqual(handled.map(\.toolCallID), ["call_1", "call_1"])
    }

    func testNoHandlerRunsForACallWithoutItsFunctionName() async throws {
        try await receive("llm-function-call-in-progress", data: .object(["tool_call_id": "call_1"]))
        XCTAssertEqual(handled.count, 0)
        XCTAssertEqual(results, [])
        XCTAssertEqual(delegate.calls.map(\.name), ["onLLMFunctionCallInProgress"])
    }

    func testAHandlerAnswersTheDeprecatedFunctionCall() async throws {
        try await receive(
            "llm-function-call",
            data: .object([
                "function_name": "get_weather", "tool_call_id": "call_1", "args": .object(["city": "Lisbon"]),
            ])
        )
        try await waitForSent(count: 1)
        try await waitForCalls()
        XCTAssertEqual(handled.map(\.toolCallID), ["call_1"])
        XCTAssertEqual(results.map { $0["tool_call_id"] }, ["call_1"])
        XCTAssertEqual(delegate.calls.map(\.name), ["onLLMFunctionCall"])
    }

    func testTheCallsLifecycleReachesTheApp() async throws {
        try await receive("llm-function-call-started", data: .object(["function_name": "get_weather"]))
        try await receive(
            "llm-function-call-stopped",
            data: .object(["tool_call_id": "call_1", "cancelled": .bool(false), "function_name": "get_weather"])
        )
        XCTAssertEqual(delegate.calls.map(\.name), ["onLLMFunctionCallStarted", "onLLMFunctionCallStopped"])
    }
}
