import XCTest
@testable import PipecatClientIOS

@MainActor
final class SendFileAndDTMFTests: ClientTestCase {
    private var sent: [JSON] {
        transport.sent.compactMap { try? JSON(encoding: $0) }
    }

    override func tearDown() async throws {
        HTTPStub.uninstall()
        try await super.tearDown()
    }

    private func assertThrows<E: Error>(_ type: E.Type, _ body: () async throws -> Void) async {
        do {
            try await body()
            XCTFail("doesn't throw \(type)")
        } catch {
            XCTAssertTrue(error is E, "throws \(error), not \(type)")
        }
    }

    /// A file too large to send in a message of `maxMessageSize`.
    private let largeFile = RTVIFile(data: Data(repeating: 7, count: 300), format: "image/png", name: "photo.png")

    private let uploaded = HTTPStub.Response(
        status: 200,
        body: .object([
            "name": "photo.png", "format": "image/png",
            "source": .object(["type": "url", "url": "pipecat:abc"]),
        ])
    )

    func testAFileIsSentWithItsContent() async throws {
        try await becomeReady()
        try await client.sendFile(
            file: RTVIFile(data: Data("hello".utf8), format: "text/plain", name: "hello.txt"),
            content: "What does it say?"
        )
        XCTAssertEqual(
            sent.map { $0["data"] },
            [
                .object([
                    "content": "What does it say?",
                    "file": .object([
                        "format": "text/plain", "name": "hello.txt",
                        "source": .object(["type": "bytes", "bytes": "aGVsbG8="]),
                    ]),
                ])
            ]
        )
    }

    func testAFileIsSentWithItsURL() async throws {
        try await becomeReady()
        try await client.sendFile(
            file: RTVIFile(url: "https://example.com/photo.png", format: "image/png"),
            content: "What's this?"
        )
        XCTAssertEqual(
            sent.first?["data"]?["file"]?["source"],
            .object(["type": "url", "url": "https://example.com/photo.png"])
        )
    }

    func testABotOlderThan2_2DoesNotTakeFiles() async throws {
        try await becomeReady(version: "2.1.0")
        await assertThrows(UnsupportedFeatureError.self) {
            try await self.client.sendFile(
                file: RTVIFile(url: "https://example.com/a.png", format: "image/png"),
                content: ""
            )
        }
        XCTAssertEqual(transport.sent.count, 0)
    }

    func testAFileTooLargeForAMessageIsUploadedAndSentByItsURL() async throws {
        setUpClient(fileUploadEndpoint: URL(string: "https://bot.example.com/files"))
        transport.maxMessageSize = 300
        HTTPStub.install(["https://bot.example.com/files": uploaded])
        try await becomeReady()
        try await client.sendFile(file: largeFile, content: "What's this?")

        let upload = try XCTUnwrap(HTTPStub.requests.first)
        XCTAssertEqual(upload.request.httpMethod, "POST")
        let contentType = try XCTUnwrap(upload.request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary="))
        let body = String(decoding: upload.body, as: UTF8.self)
        XCTAssertTrue(body.contains(#"Content-Disposition: form-data; name="file"; filename="photo.png""#))
        XCTAssertTrue(upload.body.range(of: Data(repeating: 7, count: 300)) != nil)
        XCTAssertEqual(
            sent.map { $0["data"]?["file"] },
            [
                .object([
                    "format": "image/png", "name": "photo.png",
                    "source": .object(["type": "url", "url": "pipecat:abc"]),
                ])
            ]
        )
    }

    func testTheUploadRouteTheStartBotResponseAdvertisesIsUsed() async throws {
        setUpClient(fileUploadEndpoint: URL(string: "https://elsewhere.example.com/files"))
        transport.maxMessageSize = 300
        HTTPStub.install([
            "https://bot.example.com/start": .init(status: 200, body: .object(["fileUploadUrl": "/sessions/s1/files"])),
            "https://bot.example.com/sessions/s1/files": uploaded,
        ])
        let _: Value = try await client.startBot(
            startBotParams: APIRequest(
                endpoint: URL(string: "https://bot.example.com/start")!,
                headers: [["Authorization": "Bearer key"]]
            )
        )
        try await becomeReady()
        try await client.sendFile(file: largeFile, content: "What's this?")

        let upload = try XCTUnwrap(HTTPStub.requests.last)
        XCTAssertEqual(upload.request.url?.absoluteString, "https://bot.example.com/sessions/s1/files")
        XCTAssertEqual(upload.request.value(forHTTPHeaderField: "Authorization"), "Bearer key")
        XCTAssertEqual(sent.first?["data"]?["file"]?["source"]?["url"], "pipecat:abc")
    }

    func testAFileTooLargeForAMessageNeedsSomewhereToBeUploaded() async throws {
        transport.maxMessageSize = 300
        try await becomeReady()
        await assertThrows(OtherError.self) {
            try await self.client.sendFile(file: self.largeFile, content: "What's this?")
        }
        XCTAssertEqual(transport.sent.count, 0)
    }

    func testAFailedUploadSendsNothing() async throws {
        setUpClient(fileUploadEndpoint: URL(string: "https://bot.example.com/files"))
        transport.maxMessageSize = 300
        HTTPStub.install(["https://bot.example.com/files": .init(status: 503, body: "File upload is disabled")])
        try await becomeReady()
        await assertThrows(HttpError.self) {
            try await self.client.sendFile(file: self.largeFile, content: "What's this?")
        }
        XCTAssertEqual(transport.sent.count, 0)
    }

    func testDTMFKeysAreSentInOneMessage() async throws {
        try await becomeReady(version: "2.1.0")
        try client.sendDTMF(dtmf: "12*#")
        XCTAssertEqual(sent.map { $0["data"] }, [.object(["buttons": .array(["1", "2", "*", "#"])])])
    }

    func testABotOf2_0GetsAMessageAKey() async throws {
        try await becomeReady(version: "2.0.0")
        try client.sendDTMF(dtmf: "1#")
        XCTAssertEqual(sent.map { $0["data"] }, [.object(["button": "1"]), .object(["button": "#"])])
    }

    func testOnlyKeysAreSentAsDTMF() async throws {
        try await becomeReady()
        for dtmf in ["", "12a", "1 2"] {
            XCTAssertThrowsError(try client.sendDTMF(dtmf: dtmf)) { error in
                XCTAssertTrue(error is OtherError)
            }
        }
        XCTAssertEqual(transport.sent.count, 0)
    }

    func testABotOlderThan2_0DoesNotTakeDTMF() async throws {
        try await becomeReady(version: "1.1.0")
        XCTAssertThrowsError(try client.sendDTMF(dtmf: "1")) { error in
            XCTAssertTrue(error is UnsupportedFeatureError)
        }
    }
}
