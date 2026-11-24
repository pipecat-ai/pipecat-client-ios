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

    func onLocalAudioLevel(level: Float) {
        record("onLocalAudioLevel")
    }

    func onBotStartedSpeaking() {
        record("onBotStartedSpeaking")
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
                transportDelegate?.onLocalAudioLevel(level: 0.5)
            }
        try await waitForCalls(count: 1)
        XCTAssertEqual(threadDelegate.calls.first?.name, "onLocalAudioLevel")
        XCTAssertEqual(threadDelegate.calls.first?.onMain, true)
    }

    func testTransportEventOnTheMainThreadReachesTheDelegateAtOnce() async throws {
        transport.delegate?.onTransportStateChanged(state: .connecting)
        XCTAssertEqual(threadDelegate.calls.map(\.name), ["onTransportStateChanged"])
        XCTAssertEqual(threadDelegate.calls.first?.onMain, true)
    }

    func testMessageFromAnotherThreadReachesTheDelegateOnTheMainThread() async throws {
        let transport = self.transport!
        DispatchQueue.global()
            .async {
                try? transport.receive(.object(["label": "rtvi-ai", "type": "bot-started-speaking"]))
            }
        try await waitForCalls(count: 1)
        XCTAssertEqual(threadDelegate.calls.first?.name, "onBotStartedSpeaking")
        XCTAssertEqual(threadDelegate.calls.first?.onMain, true)
    }
}
