# 1.1.0 — Unreleased

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
