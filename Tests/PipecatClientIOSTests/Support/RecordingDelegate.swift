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

    func onUserTranscript(data: Transcript) {
        record("onUserTranscript", data)
    }

    @available(*, deprecated)
    func onBotTranscript(data: BotLLMText) {
        record("onBotTranscript", data)
    }

    func onBotLlmText(data: BotLLMText) {
        record("onBotLlmText", data)
    }

    func onBotLlmStarted() {
        record("onBotLlmStarted")
    }

    func onBotLlmStopped() {
        record("onBotLlmStopped")
    }

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

    func onLLMFunctionCall(functionCallData: LLMFunctionCallData, onResult: ((Value) async -> Void)) async {
        record("onLLMFunctionCall", functionCallData)
    }

    func onBotOutput(data: BotOutputData) {
        record("onBotOutput", data)
    }
}
