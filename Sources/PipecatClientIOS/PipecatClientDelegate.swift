import Foundation

/// Callbacks invoked when changes occur in the voice session.
public protocol PipecatClientDelegate: AnyObject {
    /// Invoked when the underlying transport has connected.
    func onConnected()

    /// Invoked when the underlying transport has disconnected.
    func onDisconnected()

    /// Invoked when an error occurs.
    func onError(message: RTVIMessageInbound)

    /// Invoked when the session state has changed.
    func onTransportStateChanged(state: TransportState)

    /// Invoked when the bot has connected to the session.
    func onBotConnected(participant: Participant)
    
    /// Invoked when the bot process has started.
    func onBotStarted(botResponse: Any)

    /// Invoked when the bot has indicated it is ready for commands.
    func onBotReady(botReadyData: BotReadyData)

    /// Invoked when the bot has disconnected from the session.
    func onBotDisconnected(participant: Participant)

    /// Invoked when session metrics are received.
    func onMetrics(data: PipecatMetrics)

    /// Invoked when a message from the backend is received which was not handled by the VoiceClient or a registered helper.
    func onServerMessage(data: Any)

    /// Invoked when a message error occurs.
    func onMessageError(message: RTVIMessageInbound)

    /// Invoked when a participant has joined the session.
    func onParticipantJoined(participant: Participant)

    /// Invoked when a participant has left the session.
    func onParticipantLeft(participant: Participant)

    /// Invoked when the list of available cameras has changed.
    func onAvailableCamsUpdated(cams: [MediaDeviceInfo])

    /// Invoked when the list of available microphones has updated.
    func onAvailableMicsUpdated(mics: [MediaDeviceInfo])

    /// Invoked when the list of available speakers has updated.
    func onAvailableSpeakersUpdated(speakers: [MediaDeviceInfo])

    /// Invoked when the selected cam has changed.
    func onCamUpdated(cam: MediaDeviceInfo?)

    /// Invoked when the selected microphone has changed.
    func onMicUpdated(mic: MediaDeviceInfo?)

    /// Invoked when the selected speaker has changed.
    func onSpeakerUpdated(speaker: MediaDeviceInfo?)

    /// Invoked when a track starts.
    func onTrackStarted(track: MediaStreamTrack, participant: Participant?)

    /// Invoked when a track stops.
    func onTrackStopped(track: MediaStreamTrack, participant: Participant?)

    /// Invoked when a screen track starts.
    func onScreenTrackStarted(track: MediaStreamTrack, participant: Participant?)

    /// Invoked when a screen track stops.
    func onScreenTrackStopped(track: MediaStreamTrack, participant: Participant?)

    /// Invoked when a screen share error occurs.
    func onScreenShareError(errorMessage: String)

    /// Invoked regularly with the volume of the locally captured audio.
    func onLocalAudioLevel(level: Float)

    /// Invoked regularly with the audio volume of each remote participant.
    func onRemoteAudioLevel(level: Float, participant: Participant)

    /// Invoked when the bot starts talking.
    func onBotStartedSpeaking()

    /// Invoked when the bot stops talking.
    func onBotStoppedSpeaking()

    /// Invoked when the local user starts talking.
    func onUserStartedSpeaking()

    /// Invoked when the local user stops talking.
    func onUserStoppedSpeaking()

    /// Invoked when user transcript data is available.
    func onUserTranscript(data: Transcript)

    /// Invoked when bot transcript data is available.
    func onBotTranscript(data: BotLLMText)

    /// Invoked when received the bot transcription from the LLM.
    func onBotLlmText(data: BotLLMText)

    /// Invoked when the bot LLM text has started.
    func onBotLlmStarted()

    /// Invoked when the bot LLM text has stopped.
    func onBotLlmStopped()

    /// Invoked when text is spoken by the bot.
    func onBotTtsText(data: BotTTSText)

    /// Invoked when the bot TTS text has started.
    func onBotTtsStarted()

    /// Invoked when the bot TTS text has stopped.
    func onBotTtsStopped()

    /// Invoked when we receive a bot LLM search response.
    func onBotLlmSearchResponse(data: BotLLMSearchResponseData)

    /// Invoked when the LLM attempts to invoke a function. The provided callback must be provided with a return value.
    func onLLMFunctionCall(functionCallData: LLMFunctionCallData, onResult: ((Value) async -> Void)) async
}

extension PipecatClientDelegate {
    public func onConnected() {}
    public func onDisconnected() {}
    public func onError(message: RTVIMessageInbound) {}
    public func onTransportStateChanged(state: TransportState) {}
    public func onBotConnected(participant: Participant) {}
    public func onBotReady(botReadyData: BotReadyData) {}
    public func onBotStarted(botResponse: Any) {}
    public func onBotDisconnected(participant: Participant) {}
    public func onMetrics(data: PipecatMetrics) {}
    public func onServerMessage(data: Any) {}
    public func onMessageError(message: RTVIMessageInbound) {}
    public func onParticipantJoined(participant: Participant) {}
    public func onParticipantLeft(participant: Participant) {}
    public func onAvailableCamsUpdated(cams: [MediaDeviceInfo]) {}
    public func onAvailableMicsUpdated(mics: [MediaDeviceInfo]) {}
    public func onAvailableSpeakersUpdated(speakers: [MediaDeviceInfo]) {}
    public func onCamUpdated(cam: MediaDeviceInfo?) {}
    public func onMicUpdated(mic: MediaDeviceInfo?) {}
    public func onSpeakerUpdated(speaker: MediaDeviceInfo?) {}
    public func onTrackStarted(track: MediaStreamTrack, participant: Participant?) {}
    public func onTrackStopped(track: MediaStreamTrack, participant: Participant?) {}
    public func onScreenTrackStarted(track: MediaStreamTrack, participant: Participant?) {}
    public func onScreenTrackStopped(track: MediaStreamTrack, participant: Participant?) {}
    public func onScreenShareError(errorMessage: String) {}
    public func onLocalAudioLevel(level: Float) {}
    public func onRemoteAudioLevel(level: Float, participant: Participant) {}
    public func onBotStartedSpeaking() {}
    public func onBotStoppedSpeaking() {}
    public func onUserStartedSpeaking() {}
    public func onUserStoppedSpeaking() {}
    public func onUserTranscript(data: Transcript) {}
    public func onBotTranscript(data: BotLLMText) {}
    public func onBotLlmText(data: BotLLMText) {}
    public func onBotLlmStarted() {}
    public func onBotLlmStopped() {}
    public func onBotTtsText(data: BotTTSText) {}
    public func onBotTtsStarted() {}
    public func onBotTtsStopped() {}
    public func onBotLlmSearchResponse(data: BotLLMSearchResponseData) {}
    public func onLLMFunctionCall(functionCallData: LLMFunctionCallData, onResult: ((Value) async -> Void)) async {}
}
