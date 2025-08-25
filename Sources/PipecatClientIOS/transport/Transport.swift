import Foundation

/// An RTVI transport.
@MainActor
public protocol Transport {
    init()
    var delegate: PipecatClientDelegate? { get set }
    var onMessage: ((RTVIMessageInbound) -> Void)? { get set }

    func initialize(options: PipecatClientOptions)
    func initDevices() async throws
    func release()
    func connect(transportParams: TransportConnectionParams?) async throws
    func disconnect() async throws
    func getAllMics() -> [MediaDeviceInfo]
    func getAllCams() -> [MediaDeviceInfo]
    func updateMic(micId: MediaDeviceId) async throws
    func updateCam(camId: MediaDeviceId) async throws
    func selectedMic() -> MediaDeviceInfo?
    func selectedCam() -> MediaDeviceInfo?
    func enableMic(enable: Bool) async throws
    func enableCam(enable: Bool) async throws
    func isCamEnabled() -> Bool
    func isMicEnabled() -> Bool
    func sendMessage(message: RTVIMessageOutbound) throws
    func state() -> TransportState
    func setState(state: TransportState)
    func tracks() -> Tracks?
}
