import XCTest
@testable import PipecatClientIOS

/// A delegate that records, for each call, whether it ran on the main thread.
private final class ThreadRecordingDelegate: PipecatClientDelegate {
    private let lock = NSLock()
    private var _calls: [(name: String, onMain: Bool)] = []

    var calls: [(name: String, onMain: Bool)] {
        lock.lock()
        defer { lock.unlock() }
        return _calls
    }

    private func record(_ name: String) {
        lock.lock()
        _calls.append((name, Thread.isMainThread))
        lock.unlock()
    }

    func onTransportStateChanged(state: TransportState) {
        record("onTransportStateChanged")
    }

    func onClientUserAudioLevel(level: Float) {
        record("onClientUserAudioLevel")
    }

    func onBotStartedSpeaking() {
        record("onBotStartedSpeaking")
    }

    func onBotDeliveryUpdated(data: BotDeliveryUpdatedData) {
        record("onBotDeliveryUpdated")
    }
}

@MainActor
final class DelegateThreadTests: ClientTestCase {
    private var threadDelegate: ThreadRecordingDelegate!

    override func setUp() async throws {
        try await super.setUp()
        threadDelegate = ThreadRecordingDelegate()
        client.delegate = threadDelegate
    }

    private func waitForCalls(count: Int) async throws {
        for _ in 0..<1000 where threadDelegate.calls.count < count {
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        XCTAssertEqual(threadDelegate.calls.count, count)
    }

    func testTransportEventFromAnotherThreadReachesTheDelegateOnTheMainThread() async throws {
        let transportDelegate = transport.delegate
        DispatchQueue.global()
            .async {
                transportDelegate?.onClientUserAudioLevel(level: 0.5)
            }
        try await waitForCalls(count: 1)
        XCTAssertEqual(threadDelegate.calls.first?.name, "onClientUserAudioLevel")
        XCTAssertEqual(threadDelegate.calls.first?.onMain, true)
    }

    func testTransportEventOnTheMainThreadReachesTheDelegateAtOnce() async throws {
        transport.delegate?.onTransportStateChanged(state: .connecting)
        XCTAssertEqual(threadDelegate.calls.map(\.name), ["onTransportStateChanged"])
        XCTAssertEqual(threadDelegate.calls.first?.onMain, true)
    }

    func testMessageFromAnotherThreadReachesTheDelegateOnTheMainThread() async throws {
        let onMessage = try XCTUnwrap(transport.onMessage)
        let message = RTVIMessageInbound(type: "bot-started-speaking", data: nil)
        DispatchQueue.global()
            .async {
                onMessage(message)
            }
        try await waitForCalls(count: 1)
        XCTAssertEqual(threadDelegate.calls.first?.name, "onBotStartedSpeaking")
        XCTAssertEqual(threadDelegate.calls.first?.onMain, true)
    }

    func testDisconnectingFromAnotherThreadReachesTheDelegateOnTheMainThread() async throws {
        try await receive(
            "bot-output",
            data: .object(["text": "Hi", "output_type": "word", "delivery": .array(["warm"])])
        )
        let client = self.client!
        let disconnected = expectation(description: "disconnected")
        DispatchQueue.global()
            .async {
                Task { await client.disconnect { _ in disconnected.fulfill() } }
            }
        await fulfillment(of: [disconnected], timeout: 1)
        XCTAssertEqual(threadDelegate.calls.map(\.name), ["onBotDeliveryUpdated", "onBotDeliveryUpdated"])
        XCTAssertEqual(threadDelegate.calls.map(\.onMain), [true, true])
    }
}
