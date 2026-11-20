import XCTest
@testable import PipecatClientIOS

final class BotOutputDataTests: XCTestCase {
    private func decode(_ json: String) throws -> BotOutputData {
        try JSONDecoder().decode(BotOutputData.self, from: Data(json.utf8))
    }

    @available(*, deprecated)
    func testOutputTypeFillsAggregatedBy() throws {
        let data = try decode(#"{"text": "Hi.", "output_type": "sentence"}"#)
        XCTAssertEqual(data.outputType, .sentence)
        XCTAssertEqual(data.aggregatedBy, .sentence)
    }

    @available(*, deprecated)
    func testAggregatedByFillsOutputTypeForOlderBots() throws {
        let data = try decode(#"{"text": "Hi.", "aggregated_by": "word", "spoken": true}"#)
        XCTAssertEqual(data.outputType, .word)
        XCTAssertEqual(data.aggregatedBy, .word)
        XCTAssertEqual(data.spoken, true)
    }

    func testTextTypeFillsOutputType() throws {
        let data = try decode(#"{"text": "Hi.", "text_type": "sentence"}"#)
        XCTAssertEqual(data.outputType, .sentence)
    }

    func testTypesAndStatusesTheClientDoesNotNameDecode() throws {
        let data = try decode(#"{"text": "let x = 1", "output_type": "code", "spoken_status": "paused"}"#)
        XCTAssertEqual(data.outputType, BotOutputType(rawValue: "code"))
        XCTAssertEqual(data.spokenStatus, BotOutputData.SpokenStatus(rawValue: "paused"))
    }

    func testTheProtocolFieldsDecode() throws {
        let data = try decode(
            #"""
            {"text": "Hi there.", "output_type": "sentence", "segment_id": 3, "will_be_spoken": true,
             "spoken_status": "in-progress", "delivery": ["warm"],
             "spoken_progress": {"accumulated_text": "Hi", "remaining_text": " there."}}
            """#
        )
        XCTAssertEqual(data.segmentId, 3)
        XCTAssertEqual(data.willBeSpoken, true)
        XCTAssertEqual(data.spokenStatus, .inProgress)
        XCTAssertEqual(data.delivery, ["warm"])
        XCTAssertEqual(data.spokenProgress, BotOutputProgressData(accumulatedText: "Hi", remainingText: " there."))
    }

    func testAMessageWithoutAnyOutputTypeDoesNotDecode() {
        XCTAssertThrowsError(try decode(#"{"text": "Hi."}"#))
    }
}
