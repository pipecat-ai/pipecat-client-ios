import XCTest
@testable import PipecatClientIOS

/// A test of a client connected through a `TransportStub`, whose delegate
/// records what reaches the app.
@MainActor
class ClientTestCase: XCTestCase {
    var transport: TransportStub!
    var delegate: RecordingDelegate!
    var client: PipecatClient!

    override func setUp() async throws {
        setUpClient()
    }

    /// Starts over with a new client.
    func setUpClient() {
        transport = TransportStub()
        delegate = RecordingDelegate()
        client = PipecatClient(options: PipecatClientOptions(transport: transport))
        client.delegate = delegate
    }

    /// Receives a message, and waits for what it starts, such as a function call.
    func receive(_ message: JSON) async throws {
        try transport.receive(message)
        for _ in 0..<10 {
            await Task.yield()
        }
    }

    func receive(_ type: String, data: JSON? = nil) async throws {
        var message: [String: JSON] = ["label": "rtvi-ai", "type": .string(type), "id": "msg_1"]
        message["data"] = data
        try await receive(.object(message))
    }

    func becomeReady() async throws {
        try await receive("bot-ready", data: .object(["version": .string(PipecatClient.rtviProtocolVersion)]))
    }

    /// Waits, for up to a second, for the delegate to be called, which some messages do from a task.
    func waitForCalls() async throws {
        for _ in 0..<1000 where delegate.calls.isEmpty {
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    /// Waits for the client to have sent a number of messages.
    func waitForSent(count: Int) async throws {
        for _ in 0..<100 where transport.sent.count < count {
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        XCTAssertEqual(transport.sent.count, count)
    }
}

extension JSON: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .string(value)
    }
}
