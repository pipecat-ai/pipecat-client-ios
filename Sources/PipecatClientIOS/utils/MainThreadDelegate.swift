import Foundation

/// Hands a transport's events to the client's delegate on the main thread.
///
/// Transports report some events from their own threads, such as WebRTC's. An event on the main thread
/// reaches the delegate at once, in order with the client's own events; any other waits for the main
/// thread.
final class MainThreadDelegate: PipecatClientDelegate {
    weak var target: PipecatClientDelegate?

    private func forward(_ call: @escaping (PipecatClientDelegate) -> Void) {
        if Thread.isMainThread {
            if let target = self.target {
                call(target)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                if let target = self?.target {
                    call(target)
                }
            }
        }
    }

    func onConnected() {
        self.forward { $0.onConnected() }
    }

    func onDisconnected() {
        self.forward { $0.onDisconnected() }
    }

    func onError(message: RTVIMessageInbound) {
        self.forward { $0.onError(message: message) }
    }

    func onTransportStateChanged(state: TransportState) {
        self.forward { $0.onTransportStateChanged(state: state) }
    }

    func onBotConnected(participant: Participant) {
        self.forward { $0.onBotConnected(participant: participant) }
    }

    func onBotStarted(botResponse: Any) {
        self.forward { $0.onBotStarted(botResponse: botResponse) }
    }

    func onBotReady(botReadyData: BotReadyData) {
        self.forward { $0.onBotReady(botReadyData: botReadyData) }
    }

    func onBotDisconnected(participant: Participant) {
        self.forward { $0.onBotDisconnected(participant: participant) }
    }

    func onMetrics(data: PipecatMetrics) {
        self.forward { $0.onMetrics(data: data) }
    }

    func onServerMessage(data: Any) {
        self.forward { $0.onServerMessage(data: data) }
    }

    func onMessageError(message: RTVIMessageInbound) {
        self.forward { $0.onMessageError(message: message) }
    }

    func onParticipantJoined(participant: Participant) {
        self.forward { $0.onParticipantJoined(participant: participant) }
    }

    func onParticipantLeft(participant: Participant) {
        self.forward { $0.onParticipantLeft(participant: participant) }
    }

    func onAvailableCamsUpdated(cams: [MediaDeviceInfo]) {
        self.forward { $0.onAvailableCamsUpdated(cams: cams) }
    }

    func onAvailableMicsUpdated(mics: [MediaDeviceInfo]) {
        self.forward { $0.onAvailableMicsUpdated(mics: mics) }
    }

    func onAvailableSpeakersUpdated(speakers: [MediaDeviceInfo]) {
        self.forward { $0.onAvailableSpeakersUpdated(speakers: speakers) }
    }

    func onCamUpdated(cam: MediaDeviceInfo?) {
        self.forward { $0.onCamUpdated(cam: cam) }
    }

    func onMicUpdated(mic: MediaDeviceInfo?) {
        self.forward { $0.onMicUpdated(mic: mic) }
    }

    func onSpeakerUpdated(speaker: MediaDeviceInfo?) {
        self.forward { $0.onSpeakerUpdated(speaker: speaker) }
    }

    func onTrackStarted(track: MediaStreamTrack, participant: Participant?) {
        self.forward { $0.onTrackStarted(track: track, participant: participant) }
    }

    func onTrackStopped(track: MediaStreamTrack, participant: Participant?) {
        self.forward { $0.onTrackStopped(track: track, participant: participant) }
    }

    func onScreenTrackStarted(track: MediaStreamTrack, participant: Participant?) {
        self.forward { $0.onScreenTrackStarted(track: track, participant: participant) }
    }

    func onScreenTrackStopped(track: MediaStreamTrack, participant: Participant?) {
        self.forward { $0.onScreenTrackStopped(track: track, participant: participant) }
    }

    func onScreenShareError(errorMessage: String) {
        self.forward { $0.onScreenShareError(errorMessage: errorMessage) }
    }

    func onLocalAudioLevel(level: Float) {
        self.forward { $0.onLocalAudioLevel(level: level) }
    }

    func onRemoteAudioLevel(level: Float, participant: Participant) {
        self.forward { $0.onRemoteAudioLevel(level: level, participant: participant) }
    }

    func onBotStartedSpeaking() {
        self.forward { $0.onBotStartedSpeaking() }
    }

    func onBotStoppedSpeaking() {
        self.forward { $0.onBotStoppedSpeaking() }
    }

    func onUserStartedSpeaking() {
        self.forward { $0.onUserStartedSpeaking() }
    }

    func onUserStoppedSpeaking() {
        self.forward { $0.onUserStoppedSpeaking() }
    }

    @available(*, deprecated)
    func onUserTranscript(data: Transcript) {
        self.forward { $0.onUserTranscript(data: data) }
    }

    @available(*, deprecated)
    func onBotTranscript(data: BotLLMText) {
        self.forward { $0.onBotTranscript(data: data) }
    }

    @available(*, deprecated)
    func onBotLlmText(data: BotLLMText) {
        self.forward { $0.onBotLlmText(data: data) }
    }

    func onBotLlmStarted() {
        self.forward { $0.onBotLlmStarted() }
    }

    func onBotLlmStopped() {
        self.forward { $0.onBotLlmStopped() }
    }

    @available(*, deprecated)
    func onBotTtsText(data: BotTTSText) {
        self.forward { $0.onBotTtsText(data: data) }
    }

    func onBotTtsStarted() {
        self.forward { $0.onBotTtsStarted() }
    }

    func onBotTtsStopped() {
        self.forward { $0.onBotTtsStopped() }
    }

    func onBotLlmSearchResponse(data: BotLLMSearchResponseData) {
        self.forward { $0.onBotLlmSearchResponse(data: data) }
    }

    @available(*, deprecated)
    func onLLMFunctionCall(functionCallData: LLMFunctionCallData, onResult: ((Value) async -> Void)) async {
        await self.target?.onLLMFunctionCall(functionCallData: functionCallData, onResult: onResult)
    }

    func onLLMFunctionCallStarted(data: LLMFunctionCallStartedData) {
        self.forward { $0.onLLMFunctionCallStarted(data: data) }
    }

    func onLLMFunctionCallInProgress(data: LLMFunctionCallInProgressData) {
        self.forward { $0.onLLMFunctionCallInProgress(data: data) }
    }

    func onLLMFunctionCallStopped(data: LLMFunctionCallStoppedData) {
        self.forward { $0.onLLMFunctionCallStopped(data: data) }
    }

    func onBotOutput(data: BotOutputData) {
        self.forward { $0.onBotOutput(data: data) }
    }

    func onBotExpression(data: BotExpressionData) {
        self.forward { $0.onBotExpression(data: data) }
    }

    func onBotDeliveryUpdated(data: BotDeliveryUpdatedData) {
        self.forward { $0.onBotDeliveryUpdated(data: data) }
    }

    func onBotInterrupted() {
        self.forward { $0.onBotInterrupted() }
    }

    func onUserMuteStarted() {
        self.forward { $0.onUserMuteStarted() }
    }

    func onUserMuteStopped() {
        self.forward { $0.onUserMuteStopped() }
    }

    func onUserInput(data: UserInputData) {
        self.forward { $0.onUserInput(data: data) }
    }

    func onUserLlmText(data: UserLLMText) {
        self.forward { $0.onUserLlmText(data: data) }
    }

    func onVadUserStartedSpeaking() {
        self.forward { $0.onVadUserStartedSpeaking() }
    }

    func onVadUserStoppedSpeaking() {
        self.forward { $0.onVadUserStoppedSpeaking() }
    }

    func onUserAudioLevel(data: AudioLevelData) {
        self.forward { $0.onUserAudioLevel(data: data) }
    }

    func onBotAudioLevel(data: AudioLevelData) {
        self.forward { $0.onBotAudioLevel(data: data) }
    }

    func onSystemLog(data: SystemLog) {
        self.forward { $0.onSystemLog(data: data) }
    }

    func onBotLlmMarker(data: BotLLMMarkerData) {
        self.forward { $0.onBotLlmMarker(data: data) }
    }

    func onSttRawText(data: STTRawTextData) {
        self.forward { $0.onSttRawText(data: data) }
    }

    func onLlmRawText(data: LLMRawText) {
        self.forward { $0.onLlmRawText(data: data) }
    }

    func onTtsRawText(data: TTSRawText) {
        self.forward { $0.onTtsRawText(data: data) }
    }
}
