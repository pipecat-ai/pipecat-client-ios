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
    /// The largest message, in bytes, the transport sends to the bot. `PipecatClient.sendFile` uploads a file
    /// whose message is larger.
    var maxMessageSize: Int { get }
    func transformStartBotResultToConnectionParams(startBotParams: APIRequest, startBotResult: StartBotResult) throws
        -> TransportConnectionParams
}

extension Transport {
    public var maxMessageSize: Int { 64 * 1024 }

    public func transformStartBotResultToConnectionParams(startBotParams: APIRequest, startBotResult: StartBotResult)
        throws
        -> TransportConnectionParams {
        if let existingParams = startBotResult as? TransportConnectionParams {
            return existingParams
        }
        throw InvalidTransportParamsError()
    }
}
