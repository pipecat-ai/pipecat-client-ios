import Foundation

/// Configuration options when instantiating a VoiceClient.
public struct PipecatClientOptions {

    /// Transport class for media streaming
    public let transport: Transport

    /// Enable the user mic input. Defaults to true.
    public let enableMic: Bool

    /// Enable user cam input. Defaults to false.
    public let enableCam: Bool

    // TODO: need to add support for screen share in the future
    // public let enableScreenShare: Bool

    public init(transport: Transport, enableMic: Bool = true, enableCam: Bool = false) {
        self.transport = transport
        self.enableMic = enableMic
        self.enableCam = enableCam
    }

}
