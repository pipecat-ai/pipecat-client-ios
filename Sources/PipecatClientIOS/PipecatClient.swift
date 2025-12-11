import Foundation

/// An RTVI client that connects to an RTVI backend and handles bidirectional audio and video communication.
///
/// `PipecatClient` provides a high-level interface for establishing connections, managing media devices,
/// and handling real-time communication with AI bots. It supports both async/await and completion handler patterns
/// for maximum flexibility in different use cases.
@MainActor
open class PipecatClient {

    private let options: PipecatClientOptions
    public private(set) var transport: Transport

    private let messageDispatcher: MessageDispatcher

    private var devicesInitialized: Bool = false
    private var disconnectRequested: Bool = false

    private var functionCallCallbacks: [String: FunctionCallCallback] = [:]

    private lazy var onMessage: (RTVIMessageInbound) -> Void = { [weak self] (voiceMessage: RTVIMessageInbound) in
        guard let self else { return }
        guard let type = voiceMessage.type else {
            // Ignoring the message, it doesn't have a type
            return
        }
        Logger.shared.debug("Received voice message \(voiceMessage)")
        switch type {
        case RTVIMessageInbound.MessageType.BOT_READY:
            self.transport.setState(state: .ready)
            if let botReadyData = try? JSONDecoder().decode(BotReadyData.self, from: Data(voiceMessage.data!.utf8)) {
                Logger.shared.info("Bot ready: \(botReadyData)")
                self.delegate?.onBotReady(botReadyData: botReadyData)
            }
        case RTVIMessageInbound.MessageType.USER_TRANSCRIPTION:
            if let transcript = try? JSONDecoder().decode(Transcript.self, from: Data(voiceMessage.data!.utf8)) {
                self.delegate?.onUserTranscript(data: transcript)
            }
        case RTVIMessageInbound.MessageType.BOT_TRANSCRIPTION:
            if let transcript = try? JSONDecoder().decode(BotLLMText.self, from: Data(voiceMessage.data!.utf8)) {
                self.delegate?.onBotTranscript(data: transcript)
            }
        case RTVIMessageInbound.MessageType.BOT_LLM_STARTED:
            self.delegate?.onBotLlmStarted()
        case RTVIMessageInbound.MessageType.BOT_LLM_TEXT:
            if let botLLMText = try? JSONDecoder().decode(BotLLMText.self, from: Data(voiceMessage.data!.utf8)) {
                self.delegate?.onBotLlmText(data: botLLMText)
            }
        case RTVIMessageInbound.MessageType.BOT_LLM_STOPPED:
            self.delegate?.onBotLlmStopped()
        case RTVIMessageInbound.MessageType.BOT_TTS_STARTED:
            self.delegate?.onBotTtsStarted()
        case RTVIMessageInbound.MessageType.BOT_TTS_TEXT:
            if let botTTSText = try? JSONDecoder().decode(BotTTSText.self, from: Data(voiceMessage.data!.utf8)) {
                self.delegate?.onBotTtsText(data: botTTSText)
            }
        case RTVIMessageInbound.MessageType.BOT_TTS_STOPPED:
            self.delegate?.onBotTtsStopped()
        case RTVIMessageInbound.MessageType.SERVER_MESSAGE, RTVIMessageInbound.MessageType.APPEND_TO_CONTEXT_RESULT:
            if let storedData = try? JSONDecoder().decode(Value.self, from: Data(voiceMessage.data!.utf8)) {
                self.delegate?.onServerMessage(data: storedData)
            }
        case RTVIMessageInbound.MessageType.METRICS:
            if let metricsData = try? JSONDecoder()
                .decode(PipecatMetrics.self, from: Data(voiceMessage.data!.utf8)) {
                self.delegate?.onMetrics(data: metricsData)
            }
        case RTVIMessageInbound.MessageType.USER_STARTED_SPEAKING:
            self.delegate?.onUserStartedSpeaking()
        case RTVIMessageInbound.MessageType.USER_STOPPED_SPEAKING:
            self.delegate?.onUserStoppedSpeaking()
        case RTVIMessageInbound.MessageType.BOT_STARTED_SPEAKING:
            self.delegate?.onBotStartedSpeaking()
        case RTVIMessageInbound.MessageType.BOT_STOPPED_SPEAKING:
            self.delegate?.onBotStoppedSpeaking()
        case RTVIMessageInbound.MessageType.SERVER_RESPONSE:
            _ = self.messageDispatcher.resolve(message: voiceMessage)
        case RTVIMessageInbound.MessageType.ERROR_RESPONSE:
            Logger.shared.warn("RECEIVED ON ERROR_RESPONSE \(voiceMessage)")
            _ = self.messageDispatcher.reject(message: voiceMessage)
            self.delegate?.onMessageError(message: voiceMessage)
        case RTVIMessageInbound.MessageType.ERROR:
            Logger.shared.warn("RECEIVED ON ERROR \(voiceMessage)")
            _ = self.messageDispatcher.reject(message: voiceMessage)
            self.delegate?.onError(message: voiceMessage)
            if let botError = try? JSONDecoder().decode(BotError.self, from: Data(voiceMessage.data!.utf8)) {
                let errorMessage = "Received an error from the Bot: \(botError.error)"
                if botError.fatal ?? false {
                    self.disconnect(completion: nil)
                }
            }
        case RTVIMessageInbound.MessageType.LLM_FUNCTION_CALL:
            if let functionCallData = try? JSONDecoder()
                .decode(LLMFunctionCallData.self, from: Data(voiceMessage.data!.utf8)) {
                Task {
                    // Check if we have a registered handler for this function
                    if let registeredCallback = self.functionCallCallbacks[functionCallData.functionName] {
                        // Use the registered callback
                        await registeredCallback(functionCallData) { result in
                            let resultData = try? await LLMFunctionCallResult(
                                functionName: functionCallData.functionName,
                                toolCallID: functionCallData.toolCallID,
                                arguments: functionCallData.args,
                                result: result
                            )
                            .convertToRtviValue()
                            let resultMessage = RTVIMessageOutbound(
                                type: RTVIMessageOutbound.MessageType.LLM_FUNCTION_CALL_RESULT,
                                data: resultData
                            )
                            self.sendMessage(msg: resultMessage) { result in
                                if case .failure(let error) = result {
                                    Logger.shared.error("Failing to send app result message \(error)")
                                }
                            }
                        }
                    }
                    await self.delegate?
                        .onLLMFunctionCall(functionCallData: functionCallData) { result in
                            let resultData = try? await LLMFunctionCallResult(
                                functionName: functionCallData.functionName,
                                toolCallID: functionCallData.toolCallID,
                                arguments: functionCallData.args,
                                result: result
                            )
                            .convertToRtviValue()
                            let resultMessage = RTVIMessageOutbound(
                                type: RTVIMessageOutbound.MessageType.LLM_FUNCTION_CALL_RESULT,
                                data: resultData
                            )
                            self.sendMessage(msg: resultMessage) { result in
                                if case .failure(let error) = result {
                                    Logger.shared.error("Failing to send app result message \(error)")
                                }
                            }
                        }
                }
            }

        case RTVIMessageInbound.MessageType.BOT_LLM_SEARCH_RESPONSE:
            if let searchResponseData = try? JSONDecoder()
                .decode(BotLLMSearchResponseData.self, from: Data(voiceMessage.data!.utf8)) {
                self.delegate?.onBotLlmSearchResponse(data: searchResponseData)
            }
        default:
            Logger.shared.debug("[Pipecat Client] Unrecognized message type: \(type), message: \(voiceMessage)")
        }
    }

    /// The delegate object that receives PipecatClient events and callbacks.
    ///
    /// Set this property to an object conforming to `PipecatClientDelegate` to receive
    /// notifications about connection state changes, transcription events, bot responses,
    /// and other real-time events during the session.
    ///
    /// - Note: The delegate is held with a weak reference to prevent retain cycles.
    private weak var _delegate: PipecatClientDelegate?
    public weak var delegate: PipecatClientDelegate? {
        get {
            return _delegate
        }
        set {
            _delegate = newValue
            self.transport.delegate = _delegate
        }
    }

    /// Initializes a new PipecatClient instance with the specified configuration options.
    ///
    /// - Parameter options: Configuration options that specify the transport layer,
    ///   media settings, and other client behaviors.
    public init(options: PipecatClientOptions) {
        Logger.shared.info("Initializing Pipecat Client iOS version \(PipecatClient.libraryVersion)")
        self.options = options
        self.transport = options.transport
        self.messageDispatcher = MessageDispatcher.init(transport: transport)
        self.transport.onMessage = self.onMessage
        self.transport.initialize(options: options)
    }

    /// Initializes local media devices such as camera and microphone (completion-based).
    ///
    /// This method prepares the device's audio and video hardware for use in the session.
    /// Call this method before attempting to connect to ensure proper media device availability.
    ///
    /// - Parameter completion: A closure called when device initialization completes.
    ///   Contains a `Result<Void, AsyncExecutionError>` indicating success or failure.
    ///
    /// - Note: If devices are already initialized, this method returns immediately without error.
    public func initDevices(completion: ((Result<Void, AsyncExecutionError>) -> Void)?) {
        Task {
            do {
                try await self.initDevices()
                completion?(.success(()))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "initDevices", underlyingError: error)))
            }
        }
    }

    /// Sets the logging level for the PipecatClient and its components.
    ///
    /// Use this method to control the verbosity of log messages during development and debugging.
    ///
    /// - Parameter logLevel: The desired log level (e.g., `.debug`, `.info`, `.warn`, `.error`).
    public func setLogLevel(logLevel: LogLevel) {
        Logger.shared.setLogLevel(logLevel: logLevel)
    }

    /// Initializes local media devices such as camera and microphone (async/await).
    ///
    /// This method prepares the device's audio and video hardware for use in the session.
    /// Call this method before attempting to connect to ensure proper media device availability.
    ///
    /// - Throws: An error if device initialization fails due to permissions or hardware issues.
    ///
    /// - Note: If devices are already initialized, this method returns immediately without error.
    public func initDevices() async throws {
        if self.devicesInitialized {
            // There is nothing to do in this case
            return
        }
        try await self.transport.initDevices()
        self.devicesInitialized = true
    }

    private func fetchStartBot<T: Decodable>(startBotParams: APIRequest) async throws -> T {
        var request = URLRequest(url: startBotParams.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Adding the custom headers if they have been provided
        for header in startBotParams.headers {
            for (key, value) in header {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        do {
            if let customBodyParams = startBotParams.requestData {
                request.httpBody = try JSONEncoder().encode(startBotParams.requestData)
            }

            Logger.shared.debug(
                "Fetching from \(String(data: request.httpBody!, encoding: .utf8) ?? "")"
            )

            // Create a custom URLSession configuration with the timeout from APIRequest
            let urlSession: URLSession
            if let startTimeout = startBotParams.timeout {
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = startTimeout
                config.timeoutIntervalForResource = startTimeout
                urlSession = URLSession(configuration: config)
            } else {
                urlSession = URLSession.shared
            }

            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299
            else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                let message = "Error fetching: \(errorMessage)"
                Logger.shared.error(message)
                throw HttpError(message: message)
            }

            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            Logger.shared.error(error.localizedDescription)
            throw HttpError(message: "Error fetching.", underlyingError: error)
        }
    }

    private func bailIfDisconnected() -> Bool {
        if self.disconnectRequested {
            if self.transport.state() != .disconnecting && self.transport.state() != .disconnected {
                self.disconnect(completion: nil)
            }
            return true
        }
        return false
    }

    /// Initiates bot and retrieves connection parameters (async/await).
    ///
    /// This method sends a POST request to the specified endpoint to request a new bot to run
    /// and obtain the necessary parameters for establishing a transport connection.
    ///
    /// - Parameter startBotParams: API request configuration including endpoint URL, headers, and request data.
    /// - Returns: Transport connection parameters of the specified generic type.
    /// - Throws: `BotAlreadyStartedError` if a session is already active, or `StartBotError` for other failures.
    ///
    /// - Note: The client must be in a disconnected state to call this method.
    public func startBot<T: Decodable>(startBotParams: APIRequest) async throws -> T {
        if self.transport.state() == .authenticating || self.transport.state() == .connecting
            || self.transport.state() == .connected || self.transport.state() == .ready {
            throw BotAlreadyStartedError()
        }
        do {
            self.transport.setState(state: .authenticating)

            // Send POST request to start the bot
            let startBotResult: T = try await fetchStartBot(startBotParams: startBotParams)
            self.transport.setState(state: .authenticated)
            self.delegate?.onBotStarted(botResponse: startBotResult)
            return startBotResult
        } catch {
            self.disconnect(completion: nil)
            self.transport.setState(state: .disconnected)
            throw StartBotError(underlyingError: error)
        }
    }

    /// Initiates bot and retrieves connection parameters (completion-based).
    ///
    /// This method sends a POST request to the specified endpoint to request a new bot to run
    /// and obtain the necessary parameters for establishing a transport connection.
    ///
    /// - Parameters:
    ///   - startBotParams: API request configuration including endpoint URL, headers, and request data.
    ///   - completion: A closure called when the operation completes, containing the result or error.
    ///
    /// - Note: The client must be in a disconnected state to call this method.
    public func startBot<T: Decodable>(
        startBotParams: APIRequest,
        completion: ((Result<T, AsyncExecutionError>) -> Void)?
    ) {
        Task {
            do {
                let startBotResult: T = try await self.startBot(startBotParams: startBotParams)
                completion?(.success((startBotResult)))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "start", underlyingError: error)))
            }
        }
    }

    /// Establishes a transport connection with the bot service (async/await).
    ///
    /// This method creates the underlying transport connection using the provided
    /// connection parameters and waits for the bot to signal readiness.
    ///
    /// - Parameter transportParams: Connection parameters obtained from `startBot()`.
    ///
    /// - Note: Devices will be automatically initialized if not already done.
    public func connect(transportParams: TransportConnectionParams) async throws {
        if self.transport.state() == .authenticating || self.transport.state() == .connecting
            || self.transport.state() == .connected || self.transport.state() == .ready {
            throw BotAlreadyStartedError()
        }
        do {
            self.disconnectRequested = false
            if !self.devicesInitialized {
                try await self.initDevices()
            }

            if self.bailIfDisconnected() {
                return
            }

            try await self.transport.connect(transportParams: transportParams)

            if self.bailIfDisconnected() {
                return
            }
        } catch {
            self.disconnect(completion: nil)
            self.transport.setState(state: .disconnected)
            throw StartBotError(underlyingError: error)
        }
    }

    /// Establishes a transport connection with the bot service (completion-based).
    ///
    /// This method creates the underlying transport connection using the provided
    /// connection parameters and waits for the bot to signal readiness.
    ///
    /// - Parameters:
    ///   - transportParams: Connection parameters obtained from `startBot()`.
    ///   - completion: A closure called when the connection attempt completes.
    ///
    /// - Note: Devices will be automatically initialized if not already done.
    public func connect(
        transportParams: TransportConnectionParams,
        completion: ((Result<Void, AsyncExecutionError>) -> Void)?
    ) {
        Task {
            do {
                try await self.connect(transportParams: transportParams)
                completion?(.success(()))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "connect", underlyingError: error)))
            }
        }
    }

    /// Performs bot start request and connection in a single operation (async/await).
    ///
    /// This convenience method combines `startBot()` and `connect()` into a single call,
    /// handling the complete flow from authentication to established connection.
    ///
    /// - Parameter startBotParams: API request configuration for bot authentication.
    /// - Returns: The transport connection parameters used for the connection.
    /// - Throws: Various errors related to authentication or connection failures.
    public func startBotAndConnect<T: StartBotResult>(startBotParams: APIRequest) async throws -> T {
        let startBotResult: T = await try self.startBot(startBotParams: startBotParams)
        let transportParams = try self.transport.transformStartBotResultToConnectionParams(
            startBotParams: startBotParams,
            startBotResult: startBotResult
        )
        await try self.connect(transportParams: transportParams)
        return startBotResult
    }

    /// Performs bot start request and connection in a single operation (completion-based).
    ///
    /// This convenience method combines `startBot()` and `connect()` into a single call,
    /// handling the complete flow from authentication to established connection.
    ///
    /// - Parameters:
    ///   - startBotParams: API request configuration for bot authentication.
    ///   - completion: A closure called when the operation completes with the result.
    public func startBotAndConnect<T: StartBotResult>(
        startBotParams: APIRequest,
        completion: ((Result<T, AsyncExecutionError>) -> Void)?
    ) {
        Task {
            do {
                let transportParams: T = try await self.startBotAndConnect(startBotParams: startBotParams)
                completion?(.success((transportParams)))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "startBotAndConnect", underlyingError: error)))
            }
        }
    }

    /// Disconnects from the active RTVI session (async/await).
    ///
    /// This method gracefully closes the transport connection, cleans up resources,
    /// and transitions the client to a disconnected state.
    ///
    /// - Throws: An error if the disconnection process fails.
    ///
    /// - Note: This method is safe to call multiple times and when already disconnected.
    public func disconnect() async throws {
        self.transport.setState(state: .disconnecting)
        self.disconnectRequested = true
        try await self.transport.disconnect()
        self.messageDispatcher.disconnect()
    }

    /// Disconnects from the active RTVI session (completion-based).
    ///
    /// This method gracefully closes the transport connection, cleans up resources,
    /// and transitions the client to a disconnected state.
    ///
    /// - Parameter completion: A closure called when the disconnection completes.
    ///
    /// - Note: This method is safe to call multiple times and when already disconnected.
    public func disconnect(completion: ((Result<Void, AsyncExecutionError>) -> Void)?) {
        Task {
            do {
                try await self.disconnect()
                completion?(.success(()))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "disconnect", underlyingError: error)))
            }
        }
    }

    /// The current connection state of the transport layer.
    public var state: TransportState {
        self.transport.state()
    }

    /// Returns `true` if the client is connected and ready for communication.
    ///
    /// This is a convenience method that checks if the current state is either
    /// `.connected` or `.ready`, indicating an active session.
    ///
    /// - Returns: `true` if connected, `false` otherwise.
    public func connected() -> Bool {
        return [.connected, .ready].contains(self.transport.state())
    }

    /// The version string of the PipecatClient library.
    ///
    /// Use this property for debugging, logging, or displaying version information in your app.
    public var version: String {
        PipecatClient.libraryVersion
    }

    /// Returns a list of all available audio input devices.
    ///
    /// Query this property to present microphone selection options to users
    /// or to programmatically select specific audio input devices.
    ///
    /// - Returns: An array of `MediaDeviceInfo` objects representing available microphones.
    public func getAllMics() -> [MediaDeviceInfo] {
        return self.transport.getAllMics()
    }

    /// Returns a list of all available video input devices.
    ///
    /// Query this property to present camera selection options to users
    /// or to programmatically select specific video input devices.
    ///
    /// - Returns: An array of `MediaDeviceInfo` objects representing available cameras.
    public func getAllCams() -> [MediaDeviceInfo] {
        return self.transport.getAllCams()
    }

    /// Returns a list of all available audio output devices.
    ///
    /// - Returns: An array of `MediaDeviceInfo` objects representing available speakers.
    ///
    /// - Note: On mobile devices, microphone and speaker may be detected as the same device.
    public func getAllSpeakers() -> [MediaDeviceInfo] {
        // On mobile devices, the microphone and speaker are detected as the same audio device.
        self.transport.getAllMics()
    }

    /// The currently selected audio input device.
    ///
    /// This property returns the microphone currently being used for audio capture,
    /// or `nil` if no microphone is selected or available.
    public var selectedMic: MediaDeviceInfo? {
        return self.transport.selectedMic()
    }

    /// The currently selected video input device.
    ///
    /// This property returns the camera currently being used for video capture,
    /// or `nil` if no camera is selected or available.
    public var selectedCam: MediaDeviceInfo? {
        return self.transport.selectedCam()
    }

    /// The currently selected audio output device.
    ///
    /// This property returns the speaker currently being used for audio output,
    /// or `nil` if no speaker is selected or available.
    ///
    /// - Note: On mobile devices, this returns the same device as `selectedMic`.
    public var selectedSpeaker: MediaDeviceInfo? {
        // On mobile devices, the microphone and speaker are detected as the same audio device.
        return self.transport.selectedMic()
    }

    /// Switches to the specified audio input device (async/await).
    ///
    /// Use this method to programmatically change the active microphone during a session.
    ///
    /// - Parameter micId: The unique identifier of the desired microphone device.
    /// - Throws: An error if the device switch fails or the device is not available.
    public func updateMic(micId: MediaDeviceId) async throws {
        try await self.transport.updateMic(micId: micId)
    }

    /// Switches to the specified audio input device (completion-based).
    ///
    /// Use this method to programmatically change the active microphone during a session.
    ///
    /// - Parameters:
    ///   - micId: The unique identifier of the desired microphone device.
    ///   - completion: A closure called when the device switch completes.
    public func updateMic(micId: MediaDeviceId, completion: ((Result<Void, AsyncExecutionError>) -> Void)?) {
        Task {
            do {
                try await self.updateMic(micId: micId)
                completion?(.success(()))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "updateMic", underlyingError: error)))
            }
        }
    }

    /// Switches to the specified video input device (async/await).
    ///
    /// Use this method to programmatically change the active camera during a session.
    ///
    /// - Parameter camId: The unique identifier of the desired camera device.
    /// - Throws: An error if the device switch fails or the device is not available.
    public func updateCam(camId: MediaDeviceId) async throws {
        try await self.transport.updateCam(camId: camId)
    }

    /// Switches to the specified video input device (completion-based).
    ///
    /// Use this method to programmatically change the active camera during a session.
    ///
    /// - Parameters:
    ///   - camId: The unique identifier of the desired camera device.
    ///   - completion: A closure called when the device switch completes.
    public func updateCam(camId: MediaDeviceId, completion: ((Result<Void, AsyncExecutionError>) -> Void)?) {
        Task {
            do {
                try await self.updateCam(camId: camId)
                completion?(.success(()))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "updateCam", underlyingError: error)))
            }
        }
    }

    /// Switches to the specified audio output device (async/await).
    ///
    /// Use this method to programmatically change the active speaker during a session.
    ///
    /// - Parameter speakerId: The unique identifier of the desired speaker device.
    /// - Throws: An error if the device switch fails or the device is not available.
    ///
    /// - Note: On mobile devices, this affects the same device as `updateMic()`.
    public func updateSpeaker(speakerId: MediaDeviceId) async throws {
        // On mobile devices, the microphone and speaker are detected as the same audio device.
        try await self.transport.updateMic(micId: speakerId)
    }

    /// Switches to the specified audio output device (completion-based).
    ///
    /// Use this method to programmatically change the active speaker during a session.
    ///
    /// - Parameters:
    ///   - speakerId: The unique identifier of the desired speaker device.
    ///   - completion: A closure called when the device switch completes.
    ///
    /// - Note: On mobile devices, this affects the same device as `updateMic()`.
    public func updateSpeaker(speakerId: MediaDeviceId, completion: ((Result<Void, AsyncExecutionError>) -> Void)?) {
        Task {
            do {
                try await self.updateSpeaker(speakerId: speakerId)
                completion?(.success(()))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "updateSpeaker", underlyingError: error)))
            }
        }
    }

    /// Enables or disables the audio input device (async/await).
    ///
    /// Use this method to mute/unmute the microphone during a session without changing the selected device.
    ///
    /// - Parameter enable: `true` to enable (unmute) the microphone, `false` to disable (mute).
    /// - Throws: An error if the operation fails.
    public func enableMic(enable: Bool) async throws {
        try await self.transport.enableMic(enable: enable)
    }

    /// Enables or disables the audio input device (completion-based).
    ///
    /// Use this method to mute/unmute the microphone during a session without changing the selected device.
    ///
    /// - Parameters:
    ///   - enable: `true` to enable (unmute) the microphone, `false` to disable (mute).
    ///   - completion: A closure called when the operation completes.
    public func enableMic(enable: Bool, completion: ((Result<Void, AsyncExecutionError>) -> Void)?) {
        Task {
            do {
                try await self.enableMic(enable: enable)
                completion?(.success(()))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "enableMic", underlyingError: error)))
            }
        }
    }

    /// Enables or disables the video input device (async/await).
    ///
    /// Use this method to show/hide video during a session without changing the selected camera.
    ///
    /// - Parameter enable: `true` to enable (show) the camera, `false` to disable (hide).
    /// - Throws: An error if the operation fails.
    public func enableCam(enable: Bool) async throws {
        try await self.transport.enableCam(enable: enable)
    }

    /// Enables or disables the video input device (completion-based).
    ///
    /// Use this method to show/hide video during a session without changing the selected camera.
    ///
    /// - Parameters:
    ///   - enable: `true` to enable (show) the camera, `false` to disable (hide).
    ///   - completion: A closure called when the operation completes.
    public func enableCam(enable: Bool, completion: ((Result<Void, AsyncExecutionError>) -> Void)?) {
        Task {
            do {
                try await self.enableCam(enable: enable)
                completion?(.success(()))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "enableCam", underlyingError: error)))
            }
        }
    }

    /// Indicates whether the microphone is currently enabled (unmuted).
    ///
    /// - Returns: `true` if the microphone is enabled and capturing audio, `false` if muted.
    public var isMicEnabled: Bool {
        self.transport.isMicEnabled()
    }

    /// Indicates whether the camera is currently enabled (showing video).
    ///
    /// - Returns: `true` if the camera is enabled and capturing video, `false` if hidden.
    public var isCamEnabled: Bool {
        self.transport.isCamEnabled()
    }

    // TODO: need to add support for screen share in the future
    /// Enables or disables the video input device.
    /*public func enableScreenShare(enable: Bool) async throws {
    }
    public var isScreenShareEnabled: Bool {
    }*/

    /// Returns the current media tracks for all participants in the session.
    ///
    /// This property provides access to the audio and video streams for both local and remote participants.
    /// Use this to implement custom UI components for displaying participant media.
    ///
    /// - Returns: A `Tracks` object containing local and remote media track information, or `nil` if not connected.
    var tracks: Tracks? {
        return self.transport.tracks()
    }

    /// Releases all resources and cleans up the PipecatClient instance.
    ///
    /// Call this method when you're finished with the client to ensure proper cleanup
    /// of media devices, network connections, and other system resources.
    ///
    /// - Important: After calling this method, the client instance should not be used further.
    public func release() {
        self.transport.release()
    }

    func assertReady() throws {
        if self.state != .ready {
            throw BotNotReadyError()
        }
    }

    // ------ Messages
    func sendMessage(msg: RTVIMessageOutbound) throws {
        try self.transport.sendMessage(message: msg)
    }

    func sendMessage(msg: RTVIMessageOutbound, completion: ((Result<Void, AsyncExecutionError>) -> Void)?) {
        Task {
            do {
                try await self.sendMessage(msg: msg)
                completion?(.success(()))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "sendMessage", underlyingError: error)))
            }
        }
    }

    func dispatchMessage<T: Decodable>(message: RTVIMessageOutbound) async throws -> T {
        let voiceMessageResponse = try await self.messageDispatcher.dispatchAsync(message: message)
        return try JSONDecoder().decode(T.self, from: Data(voiceMessageResponse.data!.utf8))
    }

    /// Sends a one-way message to the bot without expecting a response.
    ///
    /// Use this method to send fire-and-forget messages or notifications to the bot.
    ///
    /// - Parameters:
    ///   - msgType: A string identifier for the message type.
    ///   - data: Optional message payload data.
    /// - Throws: `BotNotReadyError` if the bot is not ready, or other transport-related errors.
    public func sendClientMessage(msgType: String, data: Value? = nil) throws {
        try self.assertReady()
        try self.sendMessage(msg: .clientMessage(msgType: msgType, data: data))
    }

    /// Sends a request message to the bot and waits for a response (async/await).
    ///
    /// Use this method for request-response communication patterns with the bot.
    ///
    /// - Parameters:
    ///   - msgType: A string identifier for the request type.
    ///   - data: Optional request payload data.
    /// - Returns: The bot's response as `ClientMessageData`.
    /// - Throws: `BotNotReadyError` if the bot is not ready, or other communication errors.
    public func sendClientRequest(msgType: String, data: Value? = nil) async throws -> ClientMessageData {
        try self.assertReady()
        return try await self.dispatchMessage(
            message: .clientMessage(msgType: msgType, data: data)
        )
    }

    /// Sends a request message to the bot and waits for a response (completion-based).
    ///
    /// Use this method for request-response communication patterns with the bot.
    ///
    /// - Parameters:
    ///   - msgType: A string identifier for the request type.
    ///   - data: Optional request payload data.
    ///   - completion: A closure called when the response is received or an error occurs.
    public func sendClientRequest(
        msgType: String,
        data: Value? = nil,
        completion: ((Result<ClientMessageData, AsyncExecutionError>) -> Void)?
    ) {
        Task {
            do {
                let response = try await self.sendClientRequest(msgType: msgType, data: data)
                completion?(.success((response)))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "sendClientRequest", underlyingError: error)))
            }
        }
    }

    /// Appends a message to the bot's LLM conversation context (async/await).
    ///
    /// This method programmatically adds a message to the Large Language Model's conversation history,
    /// allowing you to inject user context, assistant responses, or other relevant
    /// information that will influence the bot's subsequent responses.
    ///
    /// The context message becomes part of the LLM's memory for the current session and will be
    /// considered when generating future responses.
    ///
    /// - Parameter message: An `LLMContextMessage` containing the role (user, assistant),
    ///   content to add to the conversation context and a flag for whether the bot should respond immediately.
    /// - Throws:
    ///   - `BotNotReadyError` if the bot is not in a ready state to accept context updates
    ///   - Communication errors if the message fails to send or receive a response
    ///
    /// - Important: The bot must be in a `.ready` state for this method to succeed.
    /// - Note: Context messages persist only for the current session and are cleared when disconnecting.
    @available(*, deprecated, message: "Use sendText() instead. This method will be removed in a future version.")
    public func appendToContext(message: LLMContextMessage) async throws {
        try self.assertReady()
        try self.sendMessage(msg: .appendToContext(msg: message))
    }

    /// Appends a message to the bot's LLM conversation context (completion-based).
    ///
    /// This method programmatically adds a message to the Large Language Model's conversation history,
    /// allowing you to inject user context, assistant responses, or other relevant
    /// information that will influence the bot's subsequent responses.
    ///
    /// The context message becomes part of the LLM's memory for the current session and will be
    /// considered when generating future responses.
    ///
    /// - Parameters:
    ///   - message: An `LLMContextMessage` containing the role (user, assistant),
    ///     content to add to the conversation context and a flag for whether the bot should respond immediately.
    ///   - completion: A closure called when the context update operation completes.
    ///     Contains a `Result<Value, AsyncExecutionError>` with either the bot's acknowledgment
    ///     response or an error describing what went wrong.
    ///
    /// - Important: The bot must be in a `.ready` state for this method to succeed.
    /// - Note: Context messages persist only for the current session and are cleared when disconnecting.
    @available(*, deprecated, message: "Use sendText() instead. This method will be removed in a future version.")
    public func appendToContext(
        message: LLMContextMessage,
        completion: ((Result<Void, AsyncExecutionError>) -> Void)?
    ) {
        Task {
            do {
                try await self.appendToContext(message: message)
                completion?(.success(()))
            } catch {
                completion?(.failure(AsyncExecutionError(functionName: "appendToContext", underlyingError: error)))
            }
        }
    }

    /// Sends a text message to the bot for processing.
    ///
    /// This method sends a text message directly to the bot, which will be processed by the
    /// Large Language Model and may generate a spoken response. Unlike `appendToContext()`,
    /// this method defaults to `run_immediately = true`, meaning the bot will process and
    /// respond to the message immediately.
    ///
    /// - Parameters:
    ///   - content: The text content to send to the bot for processing.
    ///   - options: Optional `SendTextOptions` to customize the message behavior.
    /// - Throws:
    ///   - `BotNotReadyError` if the bot is not in a ready state to accept messages
    ///   - Communication errors if the message fails to send
    ///
    /// - Important: The bot must be in a `.ready` state for this method to succeed.
    /// - Note: This is the preferred method for sending text messages to the bot.
    public func sendText(content: String, options: SendTextOptions? = nil) throws {
        try self.assertReady()
        try self.sendMessage(msg: .sendText(content: content, options: options))
    }

    /// Sends a disconnect signal to the bot while maintaining the transport connection.
    ///
    /// This method instructs the bot to gracefully end the current conversation session
    /// and clean up its internal state, but keeps the underlying transport connection
    /// (WebRTC, WebSocket, etc.) active. This is different from `disconnect()` which
    /// closes the entire connection.
    ///
    /// - Throws:
    ///   - `BotNotReadyError` if the bot is not in a ready state to accept the disconnect command
    ///   - Transport errors if the disconnect message fails to send
    ///
    /// - Important: The bot must be in a `.ready` state for this method to succeed.
    /// - Note: This method sends a fire-and-forget message and does not wait for acknowledgment.
    ///   The bot state change will be reflected through delegate callbacks.
    /// - SeeAlso: `disconnect()` for closing the entire transport connection.
    public func disconnectBot() throws {
        try self.assertReady()
        try self.sendMessage(
            msg: .disconnectBot()
        )
    }

    /// Registers a function call handler for a specific function name.
    ///
    /// When the bot calls a function with the specified name, the registered callback
    /// will be invoked instead of the delegate's `onLLMFunctionCall` method.
    ///
    /// - Parameters:
    ///   - functionName: The name of the function to handle.
    ///   - callback: The callback to invoke when this function is called.
    public func registerFunctionCallHandler(
        functionName: String,
        callback: @escaping FunctionCallCallback
    ) {
        functionCallCallbacks[functionName] = callback
    }

    /// Unregisters a function call handler for a specific function name.
    ///
    /// After calling this method, function calls with the specified name will
    /// be handled by the delegate's `onLLMFunctionCall` method instead.
    ///
    /// - Parameter functionName: The name of the function to unregister.
    public func unregisterFunctionCallHandler(functionName: String) {
        functionCallCallbacks.removeValue(forKey: functionName)
    }

    /// Unregisters all function call handlers.
    ///
    /// After calling this method, all function calls will be handled by
    /// the delegate's `onLLMFunctionCall` method.
    public func unregisterAllFunctionCallHandlers() {
        functionCallCallbacks.removeAll()
    }

}
