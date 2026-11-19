import Foundation
@testable import PipecatClientIOS

/// A delegate that records each call a server message brings, with the JSON of
/// what it was given.
final class RecordingDelegate: PipecatClientDelegate {
    struct Call {
        let name: String
        let data: JSON?
    }

    private(set) var calls: [Call] = []

    private func record(_ name: String, _ data: Encodable? = nil) {
        calls.append(Call(name: name, data: data.flatMap { try? JSON(encoding: $0) }))
    }

    /// Records a message the delegate is given as it arrived, by its data.
    private func record(_ name: String, message: RTVIMessageInbound) {
        calls.append(Call(name: name, data: message.data.flatMap { try? JSON(parsing: $0) }))
    }

    func onError(message: RTVIMessageInbound) {
        record("onError", message: message)
    }

    func onMessageError(message: RTVIMessageInbound) {
        record("onMessageError", message: message)
    }

    func onBotReady(botReadyData: BotReadyData) {
        record("onBotReady", botReadyData)
    }

    func onMetrics(data: PipecatMetrics) {
        record("onMetrics", data)
    }

    func onServerMessage(data: Any) {
        record("onServerMessage", data as? Encodable)
    }

    func onBotStartedSpeaking() {
        record("onBotStartedSpeaking")
    }

    func onBotStoppedSpeaking() {
        record("onBotStoppedSpeaking")
    }

    func onUserStartedSpeaking() {
        record("onUserStartedSpeaking")
    }

    func onUserStoppedSpeaking() {
        record("onUserStoppedSpeaking")
    }

    @available(*, deprecated)
    func onUserTranscript(data: Transcript) {
        record("onUserTranscript", data)
    }

    @available(*, deprecated)
    func onBotTranscript(data: BotLLMText) {
        record("onBotTranscript", data)
    }

    @available(*, deprecated)
    func onBotLlmText(data: BotLLMText) {
        record("onBotLlmText", data)
    }

    func onBotLlmStarted() {
        record("onBotLlmStarted")
    }

    func onBotLlmStopped() {
        record("onBotLlmStopped")
    }

    @available(*, deprecated)
    func onBotTtsText(data: BotTTSText) {
        record("onBotTtsText", data)
    }

    func onBotTtsStarted() {
        record("onBotTtsStarted")
    }

    func onBotTtsStopped() {
        record("onBotTtsStopped")
    }

    func onBotLlmSearchResponse(data: BotLLMSearchResponseData) {
        record("onBotLlmSearchResponse", data)
    }

    func onLLMFunctionCallStarted(data: LLMFunctionCallStartedData) {
        record("onLLMFunctionCallStarted", data)
    }

    func onLLMFunctionCallInProgress(data: LLMFunctionCallInProgressData) {
        record("onLLMFunctionCallInProgress", data)
    }

    func onLLMFunctionCallStopped(data: LLMFunctionCallStoppedData) {
        record("onLLMFunctionCallStopped", data)
    }

    @available(*, deprecated)
    func onLLMFunctionCall(functionCallData: LLMFunctionCallData, onResult: ((Value) async -> Void)) async {
        record("onLLMFunctionCall", functionCallData)
    }

    func onBotOutput(data: BotOutputData) {
        record("onBotOutput", data)
    }

    func onBotExpression(data: BotExpressionData) {
        switch data {
        case .sound(let sound):
            calls.append(Call(name: "onBotExpression", data: .object(["sound": .string(sound)])))
        case .pause(let durationMs):
            calls.append(Call(name: "onBotExpression", data: .object(["duration_ms": .number(Double(durationMs))])))
        }
    }

    func onBotDeliveryUpdated(data: BotDeliveryUpdatedData) {
        func names(_ delivery: [String]?) -> JSON {
            delivery.map { .array($0.map(JSON.string)) } ?? .null
        }
        calls.append(
            Call(
                name: "onBotDeliveryUpdated",
                data: .object(["delivery": names(data.delivery), "previous": names(data.previous)])
            )
        )
    }

    func onBotInterrupted() {
        record("onBotInterrupted")
    }

    func onUserMuteStarted() {
        record("onUserMuteStarted")
    }

    func onUserMuteStopped() {
        record("onUserMuteStopped")
    }

    func onUserInput(data: UserInputData) {
        record("onUserInput", data)
    }

    func onUserLlmText(data: UserLLMText) {
        record("onUserLlmText", data)
    }

    func onVadUserStartedSpeaking() {
        record("onVadUserStartedSpeaking")
    }

    func onVadUserStoppedSpeaking() {
        record("onVadUserStoppedSpeaking")
    }

    func onUserAudioLevel(data: AudioLevelData) {
        record("onUserAudioLevel", data)
    }

    func onBotAudioLevel(data: AudioLevelData) {
        record("onBotAudioLevel", data)
    }

    func onSystemLog(data: SystemLog) {
        record("onSystemLog", data)
    }

    func onBotLlmMarker(data: BotLLMMarkerData) {
        record("onBotLlmMarker", data)
    }

    func onSttRawText(data: STTRawTextData) {
        record("onSttRawText", data)
    }

    func onLlmRawText(data: LLMRawText) {
        record("onLlmRawText", data)
    }

    func onTtsRawText(data: TTSRawText) {
        record("onTtsRawText", data)
    }
}
