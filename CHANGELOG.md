# Unreleased

### Added

- Added support for RTVI protocol 2.3.0: `PipecatClient.rtviProtocolVersion` is now `"2.3.0"`. The protocol's types are generated from Pipecat's AsyncAPI document of the protocol, vendored in `spec/`, by `scripts/rtvi_protocol.py`.
- Function calls the bot reports with `llm-function-call-in-progress` now run the handler registered with `registerFunctionCallHandler()`, which answers the bot with its result. New delegate methods `onLLMFunctionCallStarted`, `onLLMFunctionCallInProgress` and `onLLMFunctionCallStopped` report a call's lifecycle.
- New delegate methods for the rest of the bot's messages: `onBotInterrupted`, `onUserMuteStarted`, `onUserMuteStopped`, `onUserInput`, `onUserLlmText`, `onVadUserStartedSpeaking`, `onVadUserStoppedSpeaking`, `onServerUserAudioLevel`, `onServerBotAudioLevel`, `onSystemLog`, `onBotLlmMarker`, `onSttRawText`, `onLlmRawText` and `onTtsRawText`. Each has an empty default implementation.
- `onClientUserAudioLevel` and `onClientBotAudioLevel` report how loud the user's and the bot's audio are, as the transport measures them on the device. Their names set them apart from `onServerUserAudioLevel` and `onServerBotAudioLevel`, which report the levels the bot measures.
- Expressive conversation (alpha): `onBotExpression` reports a sound, such as a laugh, or a pause the bot performed, and `onBotDeliveryUpdated` reports when the bot's delivery, such as `["warm"]`, changes. Both are derived from `bot-output`.
- `BotOutputData` has `outputType`, which bots older than 2.3.0 fill in through `aggregated_by`, and `delivery`.
- `BotReadyData` has `capabilities`, what the bot does in the session (RTVI 2.2.0+), and `PipecatMetrics` exposes all of its metrics: `processing`, `ttfb`, `ttfa`, `ttfat`, `tokens`, `sttUsage` and `characters`.
- Added `sendFile(file:content:options:)`, which sends the bot's LLM a file with text that goes with it (RTVI 2.2.0+). Build the file with `RTVIFile(data:format:name:)` or `RTVIFile(url:format:name:)`. A file too large for the transport to send in a message is uploaded first, to the `fileUploadUrl` the start-bot response advertises or else the new `PipecatClientOptions.fileUploadEndpoint`, and sent by its URL. Transports report how large a message they send with the new `Transport.maxMessageSize`, 64 KiB by default.
- Added `sendDTMF(dtmf:)`, which sends DTMF keypresses such as `"123#"` (RTVI 2.0.0+).

### Changed

- ⚠️ `BotOutputType` (formerly `BotOutputData.AggregationType`) and `BotOutputData.SpokenStatus` take values the client doesn't name, so a `bot-output` with an output type of the bot's own, such as `"code"`, now reaches `onBotOutput`. They are structs of constants instead of enums: a `switch` over them needs a `default` case.
- ⚠️ `BotError.fatal` is a `Bool` instead of a `Bool?`, as the protocol always sends it.
- `BotLLMText` and `BotTTSText` are aliases of `TextMessageData`, the data every text message carries, as are the new `UserLLMText`, `LLMRawText`, `TTSRawText` and `SystemLog`. `PipecatMetricsData` is an alias of `ProcessingMetricsData`. They have the same fields as before.

### Deprecated

- `onUserTranscript` is deprecated: use `onUserInput` to show what the user said, or `onSttRawText` to inspect what the STT produced.
- `onBotLlmText` is deprecated: use `onBotOutput` to show the bot's text, or `onLlmRawText` to inspect what the LLM produced.
- `onBotTtsText` is deprecated: use `onBotOutput` to show the bot's text, or `onTtsRawText` to inspect what the TTS produced.
- `onLLMFunctionCall` is deprecated: use `registerFunctionCallHandler()` to answer a function call, or `onLLMFunctionCallInProgress` to follow it. Only bots that send the deprecated `llm-function-call` invoke it.
- `onLocalAudioLevel` and `onRemoteAudioLevel` are deprecated: use `onClientUserAudioLevel` and `onClientBotAudioLevel` instead. They're still called, after the new ones.
- `BotOutputData.aggregatedBy` and `BotOutputData.AggregationType` are deprecated in favour of `outputType` and `BotOutputType`, and `init(text:spoken:aggregatedBy:...)` in favour of `init(text:outputType:...)`.

### Removed

- Removed `LLMFunctionCallResult`, which apps couldn't create.

### Fixed

- `PipecatClientDelegate` callbacks now arrive on the main thread. A transport that reports events or messages from its own threads, as SmallWebRTC's WebRTC does, could call the delegate off the main thread, and an app updating its UI there could crash.
- `PipecatClient.tracks` is public, as its documentation describes.

# 1.3.0 — 2026-07-02

### Added

- Added support for RTVI protocol 2.0.0. `BotOutputData` now includes new fields: `willBeSpoken`, `spokenStatus`, `spokenProgress`, and `segmentId`, enabling word-level TTS progress tracking. The `spoken` field is deprecated in favour of `willBeSpoken`.
- Added `PipecatClient.rtviProtocolVersion` constant (`"2.0.0"`).
- The client now logs a warning when the bot is running an older RTVI protocol version than the client.

### Fixed

- Fixed a crash in `startBot` when the request had no `requestData` and the log level was set to `.debug` or `.trace`.

# 1.2.0 — 2026-01-03

### Added

- Implemented support for the new `botOutput` RTVI message. This message is now the preferred
  way of communicating a holistic view of what the bot "says". It includes a `spoken` field, 
  indicating whether the text has been spoken along with a field, `aggregated_by`, to indicate what
  the text represents. By default, with TTS services that support word-by-word output, you can
  expect two `agggregated_by` values for `botOutput` events: `"sentence"` and `"word"`. All
  sentence events are guaranteed to be in order, while word events come in at the time of being
  spoken. This allows for building karaoke-like UIs where the sentence is displayed and each word
  is highlighted as it's spoken.  This event also provides continuity across bot output even when
  the TTS is skipped or does not exist. And if your pipeline takes advantage of customizing how
  the LLM text is aggregated, you can handle custom `aggregated_by` fields, like `"code"` or
  `"address"` or `"url"`, allowing the server to do the parsing.

# 1.1.3 — 2025-12-11

### Fixed

- Fixed memory management in message handling to ensure proper deallocation of `PipecatClient` instances.

# 1.1.2 — 2025-10-28

### Added

- Added default implementations for all optional `Transport` protocol methods to ensure backward compatibility.

# 1.1.1 — 2025-10-23

### Added

- Allowing the transports to transform `StartBotResult` into `TransportConnectionParams` when using startBotAndConnect.

# 1.1.0 — 2025-10-14

### Added

- Added new `sendText()` method to support the new RTVI `send-text` event. 
  - Note: This is a replacement for the current `appendToContext()` method and changes the default of `run_immediately` to `True`.
- New delegate function `onBotStarted`.

### Deprecated

- Deprecated `appendToContext()` in lieu of the new `sendText()` method. This sets a standard for future methods like `sendImage()`.

# 1.0.1 - 2025-09-19

### Added
- Added support for lower versions of Xcode (16.2 and below)

# 1.0.0 - 2025-08-25

### Changed
- Protocol Updates:
  - `client-ready` and `bot-ready` messages now include:
    - `version`: Specifies the RTVI protocol version.
    `about`: Provides metadata about the client platform and environment.
  - Deprecated and removed:
    - Action-related messages and methods (e.g., `action()`, `describeActions()`).
    - Service configuration messages and related methods (e.g., `getConfig()`, `updateConfig()`).
    - Helper-related utilities (e.g., `RTVIClientHelper`, `LLMHelper`).
  - Introduced new messaging types:
    - `client-message`: For sending messages from client to server.
    - `append-to-context`: To append data to the LLM context.
    - `disconnect-bot`: For disconnecting the bot
    - `server-response`: For receiving responses from the server.
    - `bot-llm-search-response`: For receiving the llm search response.

- PipecatClient Enhancements:
  - Constructor no longer accepts `params` for pipeline or endpoint configuration.
  - `connect()` method now accepts a set of parameters defined by the transport in use.

### Removed
- All action-related methods, events and types:
  - `action()`, `describeActions()`, `onActionsAvailable`, etc.
- All configuration-related methods, events and types:
  - `getConfig()`, `updateConfig()`, `describeConfig()`, `onConfigUpdated`, `onConfigDescribed`, etc.
- All helper-related methods, types, and files:
  - `RTVIClientHelper`, `registerHelper`, `LLMHelper`, etc.
- `transportExpiry()` method.

### Added
- `appendToContext()`: Ability to append data to the LLM context.
- `sendClientRequest()`: Send a message and wait for a response.
- `sendClientMessage()`: Sends a one-way message to the bot without expecting a response.
- `disconnectBot()`: Sends a disconnect signal to the bot while maintaining the transport connection.
- `registerFunctionCallHandler`: Registers a function call handler for a specific function name.
- `unregisterFunctionCallHandler`: Unregisters a function call handler for a specific function name.
- `unregisterAllFunctionCallHandlers`: Unregisters all function call handlers.
- `startBot()`: Fetches the POST endpoint for kicking off a bot process and optionally returning the connection parameters required by the transport.
- `startBotAndConnect()`: Calls both `startBot()` and `connect()`, passing any data returned from the `startBot()` endpoint to `connect()` as transport parameters.

# 0.3.6 - 2025-06-11

### Added

- New delegate function `onServerMessage`.

# 0.3.5 - 2025-04-02

### Added

- Triggering `onBotStartedSpeaking` and `onBotStoppedSpeaking` based on the RTVI events that we receive from Pipecat.

# 0.3.4 - 2025-03-20

### Added

- Made changes to enable transports to handle function calling.

# 0.3.3 - 2025-03-19

### Added

- Added improvements to support new transports to send transcription events.

# 0.3.2 - 2025-01-15

### Changed

- Refactored the `PipecatClientIOS` target to enable publishing to CocoaPods.
  - **Breaking Change:** Replace imports of `RTVIClientIOS` with `PipecatClientIOS`.

# 0.3.1 - 2025-01-03

### Added

- Added improvements to support the `GeminiLiveWebSocket` transport.

## 0.3.0 - 2024-12-10

### Changed

- Renamed the package from `RTVIClientIOS` to `PipecatClientIOS`.

## 0.2.0 - 2024-10-10

- Adding support for the HTTP action.
- Renamed:
  - `VoiceClient` to `RTVIClient`
  - `VoiceClientOptions` to `RTVIClientOptions`
  - `VoiceClientDelegate` to `RTVIClientDelete`
  - `VoiceError` to `RTVIError`
  - `VoiceClientHelper` to `RTVIClientHelper`
  - `FailedToFetchAuthBundle` to `HttpError`
- `RTVIClient()` constructor parameter changes
  - `options` is now mandatory
  - `baseUrl` has been moved to `options.params.baseUrl`
  - `baseUrl` and `endpoints` are now separate, and the endpoint names are appended to the `baseUrl`
- Moved `RTVIClientOptions.config` to `RTVIClientOptions.params.config`
- Moved `RTVIClientOptions.customHeaders` to `RTVIClientOptions.params.headers`
- Moved `RTVIClientOptions.customBodyParams` to `RTVIClientOptions.params.requestData`
- `TransportState` changes
  - Removed `Idle` state, replaced with `Disconnected`
  - Added `Disconnecting` state
- Added callbacks
  - `onBotLLMText()`
  - `onBotTTSText()`
  - `onStorageItemStored()`
