import Foundation
@testable import PipecatClientIOS

/// A transport with no connection: it records the messages the client sends,
/// and hands the client the messages a test receives.
final class TransportStub: Transport {
    weak var delegate: PipecatClientDelegate?
    var onMessage: ((RTVIMessageInbound) -> Void)?

    private(set) var sent: [RTVIMessageOutbound] = []
    private var currentState: TransportState = .disconnected

    init() {}

    /// Hands the client a message, as transports do: decoded from its JSON.
    func receive(_ message: JSON) throws {
        let data = try JSONEncoder().encode(message)
        onMessage?(try JSONDecoder().decode(RTVIMessageInbound.self, from: data))
    }

    func initialize(options: PipecatClientOptions) {}

    func initDevices() async throws {}

    func release() {}

    func connect(transportParams: TransportConnectionParams?) async throws {
        currentState = .connected
    }

    func disconnect() async throws {
        currentState = .disconnected
    }

    func getAllMics() -> [MediaDeviceInfo] {
        []
    }

    func getAllCams() -> [MediaDeviceInfo] {
        []
    }

    func updateMic(micId: MediaDeviceId) async throws {}

    func updateCam(camId: MediaDeviceId) async throws {}

    func selectedMic() -> MediaDeviceInfo? {
        nil
    }

    func selectedCam() -> MediaDeviceInfo? {
        nil
    }

    func enableMic(enable: Bool) async throws {}

    func enableCam(enable: Bool) async throws {}

    func isCamEnabled() -> Bool {
        false
    }

    func isMicEnabled() -> Bool {
        false
    }

    func sendMessage(message: RTVIMessageOutbound) throws {
        sent.append(message)
    }

    func state() -> TransportState {
        currentState
    }

    func setState(state: TransportState) {
        currentState = state
    }

    func tracks() -> Tracks? {
        nil
    }
}
