import XCTest
@testable import PipecatClientIOS

/// A delegate that records each audio level it's given, by the name of the method.
private final class LevelRecordingDelegate: PipecatClientDelegate {
    private(set) var levels: [(name: String, level: Float)] = []

    func onClientUserAudioLevel(level: Float) {
        levels.append(("onClientUserAudioLevel", level))
    }

    func onClientBotAudioLevel(level: Float) {
        levels.append(("onClientBotAudioLevel", level))
    }

    func onLocalAudioLevel(level: Float) {
        levels.append(("onLocalAudioLevel", level))
    }

    func onRemoteAudioLevel(level: Float, participant: Participant) {
        levels.append(("onRemoteAudioLevel", level))
    }
}

@MainActor
final class AudioLevelTests: ClientTestCase {
    private var levelDelegate: LevelRecordingDelegate!

    override func setUp() async throws {
        try await super.setUp()
        levelDelegate = LevelRecordingDelegate()
        client.delegate = levelDelegate
    }

    // Transports report the levels they measure through the deprecated methods.
    @available(*, deprecated)
    private func reportLocalLevel(_ level: Float) {
        transport.delegate?.onLocalAudioLevel(level: level)
    }

    @available(*, deprecated)
    private func reportRemoteLevel(_ level: Float) {
        let bot = Participant(id: ParticipantId(id: "bot"), name: "Bot", local: false)
        transport.delegate?.onRemoteAudioLevel(level: level, participant: bot)
    }

    @available(*, deprecated)
    func testTheTransportsLocalLevelReachesTheClientUserAudioLevel() async {
        reportLocalLevel(0.4)
        XCTAssertEqual(levelDelegate.levels.map(\.name), ["onClientUserAudioLevel", "onLocalAudioLevel"])
        XCTAssertEqual(levelDelegate.levels.map(\.level), [0.4, 0.4])
    }

    @available(*, deprecated)
    func testTheTransportsRemoteLevelReachesTheClientBotAudioLevel() async {
        reportRemoteLevel(0.6)
        XCTAssertEqual(levelDelegate.levels.map(\.name), ["onClientBotAudioLevel", "onRemoteAudioLevel"])
        XCTAssertEqual(levelDelegate.levels.map(\.level), [0.6, 0.6])
    }
}
