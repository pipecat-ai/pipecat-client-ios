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

    /// Where `PipecatClient.sendFile` uploads a file too large to send in a message, when the start-bot response
    /// doesn't advertise a `fileUploadUrl`. A relative URL is resolved against the start-bot endpoint.
    public let fileUploadEndpoint: URL?

    public init(transport: Transport, enableMic: Bool = true, enableCam: Bool = false, fileUploadEndpoint: URL? = nil) {
        self.transport = transport
        self.enableMic = enableMic
        self.enableCam = enableCam
        self.fileUploadEndpoint = fileUploadEndpoint
    }

}
