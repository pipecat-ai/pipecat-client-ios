import XCTest
@testable import PipecatClientIOS

@MainActor
final class ExpressiveOutputTests: ClientTestCase {
    private func receiveOutput(_ text: String, type: String, delivery: [String]? = nil) async throws {
        var data: [String: JSON] = ["text": .string(text), "output_type": .string(type)]
        data["delivery"] = delivery.map { .array($0.map(JSON.string)) }
        try await receive("bot-output", data: .object(data))
    }

    private func calls(_ name: String) -> [JSON?] {
        delegate.calls.filter { $0.name == name }.map(\.data)
    }

    func testSoundsAndPausesReachTheAppAsExpressions() async throws {
        try await receiveOutput("laugh", type: "expression_sound")
        try await receiveOutput("300", type: "expression_pause")
        try await receiveOutput("Hello there.", type: "sentence")
        XCTAssertEqual(calls("onBotExpression"), [.object(["sound": "laugh"]), .object(["duration_ms": .number(300)])])
    }

    func testThePausesDurationMustBeANumber() async throws {
        try await receiveOutput("long", type: "expression_pause")
        XCTAssertEqual(calls("onBotExpression"), [])
        XCTAssertEqual(calls("onBotOutput").count, 1)
    }

    func testTheDeliveryIsReportedWhenItChanges() async throws {
        try await receiveOutput("Oh", type: "word", delivery: ["warm"])
        try await receiveOutput("that's", type: "word", delivery: ["warm"])
        try await receiveOutput("wonderful", type: "word", delivery: ["warm", "emphasis"])
        try await receiveOutput("news", type: "word", delivery: ["emphasis", "warm"])
        try await receiveOutput("Oh, that's wonderful news.", type: "sentence")
        try await receiveOutput("really", type: "word", delivery: [])
        try await receive("bot-stopped-speaking")

        func update(_ delivery: [String]?, from previous: [String]?) -> JSON {
            func names(_ delivery: [String]?) -> JSON {
                delivery.map { .array($0.map(JSON.string)) } ?? .null
            }
            return .object(["delivery": names(delivery), "previous": names(previous)])
        }
        XCTAssertEqual(
            calls("onBotDeliveryUpdated"),
            [
                update(["warm"], from: nil),
                update(["warm", "emphasis"], from: ["warm"]),
                update([], from: ["warm", "emphasis"]),
                update(nil, from: []),
            ]
        )
    }

    func testNoDeliveryIsReportedWhenTheBotStopsSpeakingWithoutOne() async throws {
        try await receive("bot-stopped-speaking")
        XCTAssertEqual(calls("onBotDeliveryUpdated"), [])
    }
}
