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

    /// Invoked regularly with how loud the user's microphone audio is, from 0 (quiet) to 1 (loud), as the transport
    /// measures it on the device.
    func onClientUserAudioLevel(level: Float)

    /// Invoked regularly with how loud the bot's audio is, from 0 (quiet) to 1 (loud), as the transport measures it
    /// on the device while playing it.
    func onClientBotAudioLevel(level: Float)

    @available(
        *,
        deprecated,
        message: "Use onClientUserAudioLevel() instead. This method will be removed in a future version."
    )
    /// Invoked regularly with the volume of the locally captured audio.
    func onLocalAudioLevel(level: Float)

    @available(
        *,
        deprecated,
        message: "Use onClientBotAudioLevel() instead. This method will be removed in a future version."
    )
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

    @available(
        *,
        deprecated,
        message:
            "Use onUserInput() to show what the user said, or onSttRawText() to inspect what the STT produced. This method will be removed in a future version."
    )
    /// Invoked when user transcript data is available.
    func onUserTranscript(data: Transcript)

    @available(*, deprecated, message: "Use onBotOutput() instead. This method will be removed in a future version.")
    /// Invoked when bot transcript data is available.
    func onBotTranscript(data: BotLLMText)

    @available(
        *,
        deprecated,
        message:
            "Use onBotOutput() to show the bot's text, or onLlmRawText() to inspect what the LLM produced. This method will be removed in a future version."
    )
    /// Invoked when received the bot transcription from the LLM.
    func onBotLlmText(data: BotLLMText)

    /// Invoked when the bot LLM text has started.
    func onBotLlmStarted()

    /// Invoked when the bot LLM text has stopped.
    func onBotLlmStopped()

    @available(
        *,
        deprecated,
        message:
            "Use onBotOutput() to show the bot's text, or onTtsRawText() to inspect what the TTS produced. This method will be removed in a future version."
    )
    /// Invoked when text is spoken by the bot.
    func onBotTtsText(data: BotTTSText)

    /// Invoked when the bot TTS text has started.
    func onBotTtsStarted()

    /// Invoked when the bot TTS text has stopped.
    func onBotTtsStopped()

    /// Invoked when we receive a bot LLM search response.
    func onBotLlmSearchResponse(data: BotLLMSearchResponseData)

    /// Invoked when the LLM starts calling a function. It carries the function's name when the bot reports it.
    func onLLMFunctionCallStarted(data: LLMFunctionCallStartedData)

    /// Invoked when the LLM is calling a function. How much it carries depends on the bot's report level for
    /// the function: only the call's id, or also the function's name and arguments.
    ///
    /// To run the function in the app and answer the bot with its result, register a handler with
    /// `PipecatClient.registerFunctionCallHandler(functionName:callback:)`.
    func onLLMFunctionCallInProgress(data: LLMFunctionCallInProgressData)

    /// Invoked when a function call finishes, or is cancelled.
    func onLLMFunctionCallStopped(data: LLMFunctionCallStoppedData)

    @available(
        *,
        deprecated,
        message:
            "Use registerFunctionCallHandler() or onLLMFunctionCallInProgress() instead. This method will be removed in a future version."
    )
    /// Invoked when the LLM attempts to invoke a function. The provided callback must be provided with a return value.
    ///
    /// Only bots that send the deprecated `llm-function-call` message invoke it.
    func onLLMFunctionCall(functionCallData: LLMFunctionCallData, onResult: ((Value) async -> Void)) async

    /// Invoked when the bot has a new output data
    func onBotOutput(data: BotOutputData)

    /// Invoked when the bot performs a sound, such as a laugh, or a pause, in expressive conversation
    /// (RTVI 2.3.0+). Derived from `onBotOutput`.
    func onBotExpression(data: BotExpressionData)

    /// Invoked when the bot's delivery changes, in expressive conversation (RTVI 2.3.0+). Derived from
    /// `onBotOutput`: invoked only when it changes, and with a `nil` delivery once the bot stops speaking.
    func onBotDeliveryUpdated(data: BotDeliveryUpdatedData)

    /// Invoked when the bot was interrupted and stopped what it was saying. The bot's text that hadn't been
    /// spoken yet won't be.
    func onBotInterrupted()

    /// Invoked when the bot stops listening to the user, for example while it says something that must not be
    /// interrupted.
    func onUserMuteStarted()

    /// Invoked when the bot listens to the user again.
    func onUserMuteStopped()

    /// Invoked with what the user said or typed: a transcription of their speech, text the client sent, or a
    /// short acknowledgment the user said while the bot talks.
    func onUserInput(data: UserInputData)

    /// Invoked with the user's message as the bot's LLM receives it.
    func onUserLlmText(data: UserLLMText)

    /// Invoked when voice activity detection hears the user start speaking. It reacts to any voice, sooner than
    /// `onUserStartedSpeaking`, which comes when the bot decides the user's turn started. The bot sends it only
    /// when enabled, with Pipecat's `vad_user_speaking_enabled` setting.
    func onVadUserStartedSpeaking()

    /// Invoked when voice activity detection hears the user stop speaking. The bot sends it only when enabled,
    /// with Pipecat's `vad_user_speaking_enabled` setting.
    func onVadUserStoppedSpeaking()

    /// Invoked regularly with how loud the user's audio is, from 0 (quiet) to 1 (loud), as the bot received it.
    /// Unlike `onClientUserAudioLevel`, which the transport measures on the device, the bot measures it. The bot
    /// sends it only when enabled, with Pipecat's `user_audio_level_enabled` setting.
    func onServerUserAudioLevel(data: AudioLevelData)

    /// Invoked regularly with how loud the bot's audio is, from 0 (quiet) to 1 (loud), as the bot produced it.
    /// Unlike `onClientBotAudioLevel`, which the transport measures on the device, the bot measures it. The bot
    /// sends it only when enabled, with Pipecat's `bot_audio_level_enabled` setting.
    func onServerBotAudioLevel(data: AudioLevelData)

    /// Invoked with a line of the bot's log, for debugging. The bot sends it only when enabled, with Pipecat's
    /// `system_logs_enabled` setting.
    func onSystemLog(data: SystemLog)

    /// Invoked with the marker the bot's LLM put in a response, outside the text it speaks, such as one saying
    /// whether the user's turn was complete. The bot sends it only when enabled, with Pipecat's
    /// `bot_llm_marker_enabled` setting.
    func onBotLlmMarker(data: BotLLMMarkerData)

    /// Invoked with a transcription of the user's speech as the bot's STT produces it, including interim
    /// transcriptions that may still change (RTVI 2.2.0+). The bot sends it only when enabled, with Pipecat's
    /// `stt_raw_text_enabled` setting.
    func onSttRawText(data: STTRawTextData)

    /// Invoked with text exactly as the bot's LLM streams it, a chunk at a time (RTVI 2.2.0+). The bot sends it
    /// only when enabled, with Pipecat's `llm_raw_text_enabled` setting.
    func onLlmRawText(data: LLMRawText)

    /// Invoked with text the bot's TTS speaks, as it speaks it (RTVI 2.2.0+). The bot sends it only when
    /// enabled, with Pipecat's `tts_raw_text_enabled` setting.
    func onTtsRawText(data: TTSRawText)
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
    public func onClientUserAudioLevel(level: Float) {}
    public func onClientBotAudioLevel(level: Float) {}
    @available(
        *,
        deprecated,
        message: "Use onClientUserAudioLevel() instead. This method will be removed in a future version."
    )
    public func onLocalAudioLevel(level: Float) {}
    @available(
        *,
        deprecated,
        message: "Use onClientBotAudioLevel() instead. This method will be removed in a future version."
    )
    public func onRemoteAudioLevel(level: Float, participant: Participant) {}
    public func onBotStartedSpeaking() {}
    public func onBotStoppedSpeaking() {}
    public func onUserStartedSpeaking() {}
    public func onUserStoppedSpeaking() {}
    @available(
        *,
        deprecated,
        message:
            "Use onUserInput() to show what the user said, or onSttRawText() to inspect what the STT produced. This method will be removed in a future version."
    )
    public func onUserTranscript(data: Transcript) {}
    @available(*, deprecated, message: "Use onBotOutput() instead. This method will be removed in a future version.")
    public func onBotTranscript(data: BotLLMText) {}
    @available(
        *,
        deprecated,
        message:
            "Use onBotOutput() to show the bot's text, or onLlmRawText() to inspect what the LLM produced. This method will be removed in a future version."
    )
    public func onBotLlmText(data: BotLLMText) {}
    public func onBotLlmStarted() {}
    public func onBotLlmStopped() {}
    @available(
        *,
        deprecated,
        message:
            "Use onBotOutput() to show the bot's text, or onTtsRawText() to inspect what the TTS produced. This method will be removed in a future version."
    )
    public func onBotTtsText(data: BotTTSText) {}
    public func onBotTtsStarted() {}
    public func onBotTtsStopped() {}
    public func onBotLlmSearchResponse(data: BotLLMSearchResponseData) {}
    public func onLLMFunctionCallStarted(data: LLMFunctionCallStartedData) {}
    public func onLLMFunctionCallInProgress(data: LLMFunctionCallInProgressData) {}
    public func onLLMFunctionCallStopped(data: LLMFunctionCallStoppedData) {}
    @available(
        *,
        deprecated,
        message:
            "Use registerFunctionCallHandler() or onLLMFunctionCallInProgress() instead. This method will be removed in a future version."
    )
    public func onLLMFunctionCall(functionCallData: LLMFunctionCallData, onResult: ((Value) async -> Void)) async {}
    public func onBotOutput(data: BotOutputData) {}
    public func onBotExpression(data: BotExpressionData) {}
    public func onBotDeliveryUpdated(data: BotDeliveryUpdatedData) {}
    public func onBotInterrupted() {}
    public func onUserMuteStarted() {}
    public func onUserMuteStopped() {}
    public func onUserInput(data: UserInputData) {}
    public func onUserLlmText(data: UserLLMText) {}
    public func onVadUserStartedSpeaking() {}
    public func onVadUserStoppedSpeaking() {}
    public func onServerUserAudioLevel(data: AudioLevelData) {}
    public func onServerBotAudioLevel(data: AudioLevelData) {}
    public func onSystemLog(data: SystemLog) {}
    public func onBotLlmMarker(data: BotLLMMarkerData) {}
    public func onSttRawText(data: STTRawTextData) {}
    public func onLlmRawText(data: LLMRawText) {}
    public func onTtsRawText(data: TTSRawText) {}
}
