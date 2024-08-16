import Foundation

/// Configuration options when instantiating a VoiceClient.
public struct VoiceClientOptions: Codable {
    /// Enable the user mic input. Defaults to true.
    public let enableMic: Bool
    
    /// Enable user cam input. Defaults to false.
    public let enableCam: Bool
    
    /// A list of services to use on the backend.
    public let services: [String: String]
    
    /// Further configuration options for the backend.
    public let config: [ServiceConfig]
    
    public init() {
        self.init(enableMic: true, enableCam: true, services: [:], config: [])
    }
    
    public init(
        enableMic: Bool = true,
        enableCam: Bool = false,
        services: [String: String] = [:],
        config: [ServiceConfig] = []
    ) {
        self.enableMic = enableMic
        self.enableCam = enableCam
        self.services = services
        self.config = config
    }
    
}
