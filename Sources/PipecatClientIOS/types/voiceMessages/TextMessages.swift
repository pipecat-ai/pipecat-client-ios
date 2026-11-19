import Foundation

/// The user's message as the bot's LLM receives it, as `user-llm-text` reports it.
public typealias UserLLMText = BotLLMText

/// A chunk of text as the bot's LLM streams it, as `llm-raw-text` reports it (RTVI 2.2.0+).
public typealias LLMRawText = BotLLMText

/// Text the bot's TTS speaks, as it speaks it, as `tts-raw-text` reports it (RTVI 2.2.0+).
public typealias TTSRawText = BotLLMText

/// A line of the bot's log, as `system-log` reports it.
public typealias SystemLog = BotLLMText
