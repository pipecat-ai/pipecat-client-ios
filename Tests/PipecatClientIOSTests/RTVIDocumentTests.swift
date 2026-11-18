import XCTest
@testable import PipecatClientIOS

/// Checks that the client speaks the RTVI protocol as its document describes
/// it: it hands every message the server sends to the app, with all of the
/// message's data, and builds every message it sends as the document's schema
/// says.
@MainActor
final class RTVIDocumentTests: ClientTestCase {
    /// Server messages the client doesn't hand to the app, and why.
    static let ignored: [String: String] = [
        "bot-interrupted": "not handled yet",
        "bot-audio-level": "not handled yet",
        "bot-llm-marker": "not handled yet",
        "bot-output": "BotOutputData requires aggregated_by, which the protocol deprecates for output_type",
        "llm-raw-text": "not handled yet",
        "stt-raw-text": "not handled yet",
        "system-log": "not handled yet",
        "tts-raw-text": "not handled yet",
        "ui-command": "it drives the elements of a web page, which iOS has no equivalent of yet",
        "ui-job-group": "it reports jobs that UI commands started, which iOS doesn't handle",
        "user-audio-level": "not handled yet",
        "user-input": "not handled yet",
        "user-llm-text": "not handled yet",
        "user-mute-started": "not handled yet",
        "user-mute-stopped": "not handled yet",
        "vad-user-started-speaking": "not handled yet",
        "vad-user-stopped-speaking": "not handled yet",
    ]

    /// Server messages answering a request: they settle it.
    static let answers: Set<String> = ["server-response", "error-response"]

    /// Message types the client knows that the document doesn't have, and why.
    static let notInDocument: [String: String] = [
        "append-to-context": "deprecated; servers no longer handle it",
        "append-to-context-result": "deprecated; servers no longer send it",
        "bot-llm-search-response": "sent only by Pipecat's Google RTVI observer, outside the protocol",
        "transcript": "removed from the protocol; servers no longer send it",
    ]

    /// Client messages the client doesn't send, and why.
    static let notSent: [String: String] = [
        "dtmf": "not supported yet",
        "raw-audio": "the transport carries the user's audio",
        "raw-audio-batch": "the transport carries the user's audio",
        "send-file": "not supported yet",
        "ui-cancel-job-group": "iOS doesn't handle UI commands",
        "ui-event": "iOS doesn't handle UI commands",
        "ui-snapshot": "iOS doesn't handle UI commands",
    ]

    private var document: RTVIDocument!

    override func setUp() async throws {
        try await super.setUp()
        document = try RTVIDocument.load(version: PipecatClient.rtviProtocolVersion)
    }

    private func receiveExample(of type: String, adding fields: [String: JSON] = [:]) async throws {
        var payload = try XCTUnwrap(document.example(of: type).object)
        if case .object(let data) = payload["data"], !fields.isEmpty {
            payload["data"] = .object(data.merging(fields) { current, _ in current })
        }
        try await receive(.object(payload))
    }

    // Messages from the server

    func testServerMessagesReachTheAppOrAreIgnoredOnPurpose() async throws {
        var unexpected: [String] = []
        for type in document.serverTypes where !Self.answers.contains(type) {
            setUpClient()
            try await receiveExample(of: type)
            let reached = !delegate.calls.isEmpty
            if reached == (Self.ignored[type] != nil) {
                unexpected.append(reached ? "\(type) reaches the app, but is ignored" : "\(type) doesn't reach the app")
            }
        }
        XCTAssertEqual(unexpected, [])
    }

    func testServerMessagesReachTheAppWithTheirData() async throws {
        var unexpected: [String] = []
        for type in delivered {
            setUpClient()
            try await receiveExample(of: type)
            if !carries(type) {
                unexpected.append(type)
            }
        }
        XCTAssertEqual(unexpected, [])
    }

    func testServerMessagesWithAFieldTheClientDoesNotKnowReachTheApp() async throws {
        var unexpected: [String] = []
        for type in delivered where document.example(of: type)["data"]?.object != nil {
            setUpClient()
            try await receiveExample(of: type, adding: ["x_unknown": .number(1)])
            if delegate.calls.isEmpty {
                unexpected.append(type)
            }
        }
        XCTAssertEqual(unexpected, [])
    }

    func testTheMessageTypesTheClientKnowsAreTheDocuments() throws {
        let documented = Set(document.serverTypes + document.clientTypes)
        let known = try Self.knownMessageTypes()
        XCTAssertEqual(known.subtracting(documented).sorted(), Self.notInDocument.keys.sorted())
    }

    private var delivered: [String] {
        document.serverTypes.filter { Self.ignored[$0] == nil && !Self.answers.contains($0) }
    }

    /// Whether a call the message brought has all of its data.
    private func carries(_ type: String) -> Bool {
        guard let data = document.example(of: type)["data"] else {
            return !delegate.calls.isEmpty
        }
        return delegate.calls.contains { $0.data?.carries(data) ?? false }
    }

    /// The message types the client's `MessageType` enums name.
    private static func knownMessageTypes() throws -> Set<String> {
        let transport = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("../../Sources/PipecatClientIOS/transport")
        var types: Set<String> = []
        for file in ["RTVIMessageInbound.swift", "RTVIMessageOutbound.swift"] {
            let source = try String(contentsOf: transport.appendingPathComponent(file), encoding: .utf8)
            let enumBody = try XCTUnwrap(source.components(separatedBy: "enum MessageType {").last)
            let regex = try NSRegularExpression(pattern: #"static let \w+ = "([^"]+)""#)
            for match in regex.matches(in: enumBody, range: NSRange(enumBody.startIndex..., in: enumBody)) {
                if let range = Range(match.range(at: 1), in: enumBody) {
                    types.insert(String(enumBody[range]))
                }
            }
        }
        return types
    }

    // Messages to the server

    func testMessagesTheClientSendsMatchTheirSchemas() async throws {
        try await becomeReady()
        client.registerFunctionCallHandler(functionName: "get_weather") { _, onResult in
            await onResult(.object(["sunny": .boolean(true)]))
        }

        try transport.sendMessage(message: .clientReady())
        try client.sendClientMessage(msgType: "set-volume", data: .object(["level": .number(5)]))
        try client.sendText(content: "What's the weather?", options: SendTextOptions(runImmediately: true))
        try await receive(
            "llm-function-call-in-progress",
            data: .object([
                "function_name": "get_weather", "tool_call_id": "call_1", "arguments": .object(["city": "Lisbon"]),
            ])
        )
        try client.disconnectBot()

        var violations: [String] = []
        for message in transport.sent {
            violations += try document.violations(of: JSON(encoding: message))
        }
        XCTAssertEqual(violations, [])
        let sent = Set(transport.sent.map(\.type))
        XCTAssertEqual(
            document.clientTypes.filter { !sent.contains($0) }.sorted(),
            Self.notSent.keys.sorted()
        )
    }

    func testAServerResponseSettlesTheRequestWithItsID() async throws {
        try await becomeReady()

        async let answered = client.sendClientRequest(msgType: "get-weather", data: .object(["city": "Lisbon"]))
        try await waitForSent(count: 1)
        var response = try XCTUnwrap(document.example(of: "server-response").object)
        response["id"] = .string(transport.sent[0].id)
        let data = try XCTUnwrap(response["data"]?.object)
        response["data"] = .object(data.merging(["t": "get-weather"]) { _, new in new })
        try await receive(.object(response))
        let answer = try await answered
        XCTAssertEqual(try answer.d.map { try JSON(encoding: $0) }, data["d"])

        async let failed = client.sendClientRequest(msgType: "get-weather", data: .object(["city": "Lisbon"]))
        try await waitForSent(count: 2)
        var error = try XCTUnwrap(document.example(of: "error-response").object)
        error["id"] = .string(transport.sent[1].id)
        try await receive(.object(error))
        do {
            _ = try await failed
            XCTFail("an error-response doesn't fail the request")
        } catch {}
    }
}

/// The RTVI protocol's AsyncAPI document the client speaks, in `spec/`.
struct RTVIDocument {
    let serverTypes: [String]
    let clientTypes: [String]
    private let messages: [String: JSON]
    private let validator: SchemaValidator

    static func load(version: String) throws -> RTVIDocument {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("../../spec/\(version)/rtvi.asyncapi.json")
        return try RTVIDocument(JSON(parsing: String(contentsOf: url, encoding: .utf8)))
    }

    init(_ document: JSON) throws {
        let components = try XCTUnwrap(document["components"])
        let byKey = try XCTUnwrap(components["messages"]?.object)
        func types(_ operation: String) throws -> [String] {
            try XCTUnwrap(document["operations"]?[operation]?["messages"]?.array)
                .map { ref in
                    let key = String(try XCTUnwrap(ref["$ref"]?.string).split(separator: "/").last ?? "")
                    return try XCTUnwrap(byKey[key]?["name"]?.string)
                }
        }
        serverTypes = try types("sendServerMessages")
        clientTypes = try types("receiveClientMessages")
        messages = Dictionary(
            uniqueKeysWithValues: byKey.values.compactMap { message in
                message["name"]?.string.map { ($0, message) }
            }
        )
        validator = SchemaValidator(schemas: components["schemas"]?.object ?? [:])
    }

    /// The first example of a message, as the server or client sends it.
    func example(of type: String) -> JSON {
        messages[type]?["examples"]?.array?.first?["payload"] ?? .null
    }

    /// What is wrong with a message the client sends, by the document's schema.
    func violations(of message: JSON) -> [String] {
        guard let type = message["type"]?.string, clientTypes.contains(type),
            let payload = messages[type]?["payload"]
        else {
            return ["\(message["type"]?.text ?? "a message without a type") isn't a message a client sends"]
        }
        return validator.violations(message, payload).map { "\(type) \($0)" }
    }
}
