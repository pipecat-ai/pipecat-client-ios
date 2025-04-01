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
