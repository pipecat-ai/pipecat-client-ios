import Foundation

/// Text the bot's LLM produced, as `bot-llm-text` and `bot-transcription` report it.
public typealias BotLLMText = TextMessageData

/// Text the bot's TTS spoke, as `bot-tts-text` reports it.
public typealias BotTTSText = TextMessageData

/// The user's message as the bot's LLM receives it, as `user-llm-text` reports it.
public typealias UserLLMText = TextMessageData

/// A chunk of text as the bot's LLM streams it, as `llm-raw-text` reports it (RTVI 2.2.0+).
public typealias LLMRawText = TextMessageData

/// Text the bot's TTS speaks, as it speaks it, as `tts-raw-text` reports it (RTVI 2.2.0+).
public typealias TTSRawText = TextMessageData

/// A line of the bot's log, as `system-log` reports it.
public typealias SystemLog = TextMessageData
