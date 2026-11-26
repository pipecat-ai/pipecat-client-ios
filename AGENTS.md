# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Repository

Swift package `PipecatClientIOS`, the iOS client SDK for [Pipecat](https://github.com/pipecat-ai/pipecat): the client side of the RTVI protocol the Pipecat server speaks. It's distributed with Swift Package Manager and CocoaPods (`PipecatClientIOS.podspec`).

Concrete transports (Daily, SmallWebRTC, Gemini Live, OpenAI Realtime) are **not** in this repo; each lives in its own `pipecat-client-ios-*` repo and implements the `Transport` protocol from this package. A change to `Transport` reaches them only once this package is released.

## Commands

```bash
# Build and test, on an iOS simulator (the package declares iOS only, so `swift build` fails on macOS)
xcodebuild test -scheme PipecatClientIOS -destination 'platform=iOS Simulator,name=iPhone 16'

# Build and test on Linux
docker run --rm -v "$PWD":/src -w /src swift:6.0 swift test

# RTVI protocol document: copy it from Pipecat's main (or --ref <tag>, or --pipecat <checkout>) and regenerate
python3 scripts/rtvi_protocol.py sync
python3 scripts/rtvi_protocol.py generate   # regenerate only
python3 scripts/rtvi_protocol.py check      # fails when the generated file is out of date

# Format and lint
swift-format format -i <files>
swift-format lint <files>
```

- The script runs on macOS's own `/usr/bin/python3` (3.9), with no dependencies: keep it to the standard library and 3.9's syntax.
- `.swift-format` sets the style (120 columns). It moves a `{` after a multi-line condition to its own line, which the existing code doesn't do; keep the file's style rather than reformatting code you didn't change. The upper-case `MessageType` constants are the SDK's public names: leave them despite `AlwaysUseLowerCamelCase`.
- Linux has no `os` module and keeps `URLSession` in `FoundationNetworking`: `Logger` writes to standard error there, and a file using `URLSession` or `URLRequest` imports `FoundationNetworking` under `#if canImport(FoundationNetworking)`.
- Linux's test discovery can't call a synchronous test method of a `@MainActor` class: the test methods of `ClientTestCase` subclasses are `async`.
- A Linux test run sometimes hangs within its first tests, waiting in XCTest's `awaitUsingExpectation` for a task that never gets a thread. It's XCTest's or libdispatch's, not the tests': run it again.

## Commits, changelog, releases

- Commit messages are plain sentences ending with a period, not Conventional Commits.
- `CHANGELOG.md` has an entry per release, with `### Added`, `### Changed`, `### Deprecated`, `### Removed` and `### Fixed` sections. Add changes under `# Unreleased`; a breaking change is marked ⚠️ and says what an app changes.
- A release sets `PipecatClient.libraryVersion` in `PipecatClientVersion.swift` and `s.version` in the podspec to the same version, and dates the changelog entry.

## Architecture

- **`PipecatClient`** (`PipecatClient.swift`) is the public entry point, `@MainActor`. It starts the bot (`startBot`, a `POST` to the app's endpoint), connects the transport, and sends client messages (`sendText`, `sendFile`, `sendDTMF`, `sendClientMessage`, `sendClientRequest`, `disconnectBot`). `onMessage` is a `switch` over `RTVIMessageInbound.MessageType` that decodes each server message and calls the delegate.
- **`PipecatClientDelegate`** (`PipecatClientDelegate.swift`) has a method for each thing the app hears about, each with an empty default in the protocol extension so apps implement only what they use. The client hands the app's delegate to the transport, which calls the connection, participant, device and track methods directly, and forwards every RTVI message to the client's `onMessage`. So the client doesn't see those calls: state it keeps, such as the bot's delivery, is reset from messages and from `disconnect()`.
- **`Transport`** (`transport/Transport.swift`) is the protocol transports implement: devices, connect and disconnect, `sendMessage`, tracks. A new requirement gets a default in the protocol's extension, so the transports in other repos keep compiling.
- **`MessageDispatcher`** (`utils/MessageDispatcher.swift`) implements request and response over RTVI: it keeps each request by its id, and settles it on the `server-response` or `error-response` carrying that id.
- **Protocol document**: `spec/<version>/rtvi.asyncapi.json` is Pipecat's AsyncAPI document of the RTVI protocol, for the version `PipecatClient.rtviProtocolVersion` names, and `generated/RTVIProtocol.swift` holds the types `scripts/rtvi_protocol.py` generates from it. Neither is edited by hand. The script's tables at its top decide what isn't generated (`SKIPPED_MESSAGES`, and `HAND_WRITTEN` types such as `BotOutputData`, which also read fields older bots send), the public names that differ from the schema's (`TYPE_NAMES`, `FIELD_NAMES`), and which client-message types apps build (`PUBLIC_CLIENT_TYPES`; other client-message types are internal). Enums are generated as structs of `static let` constants, so a value the client doesn't name still decodes. Public aliases name a generated type after a message, as `BotLLMText` and `BotTTSText` are aliases of `TextMessageData`.
- **Protocol tests**: `RTVIDocumentTests` checks the client against the document: every server message reaches the delegate or is listed in `ignored` with a reason, each example reaches it with all of its data (also with a field the client doesn't know), every message type the client names is in the document or listed in `notInDocument`, and every message the client sends matches its schema, with the client messages it never sends listed in `notSent`. A new message in the document fails these until it's handled or listed. The `update-rtvi` skill carries a new protocol version that Pipecat released through the SDK.
- Behavior that depends on the bot's protocol version reads `botVersion`, parsed from `bot-ready`: `sendFile` needs 2.2.0, and `sendDTMF` sends 2.0.x bots one message per key. A file whose message is larger than `Transport.maxMessageSize` is uploaded first, to the `fileUploadUrl` the start-bot response advertised or `PipecatClientOptions.fileUploadEndpoint`, and sent by its URL.
- Deprecated delegate methods and fields stay, marked `@available(*, deprecated, message:)` with their replacement, and the client keeps calling them: older bots still send the messages behind them. A deprecated `MessageType` constant gets a "Deprecated:" note in its doc comment instead, since the client's own `switch` uses it.

## Tests

- `Tests/PipecatClientIOSTests/Support/` holds the harness: `ClientTestCase` makes a client on a `TransportStub`, which records what the client sends and hands it messages as JSON; `RecordingDelegate` records each delegate call with its data; `JSON` compares and validates messages as they are on the wire; `HTTPStub` answers `URLSession.shared`'s requests.
- Some messages reach the delegate from a `Task`, such as a function call: wait with `waitForCalls()` or `waitForSent(count:)` instead of assuming they arrived.
- A new delegate method needs its recording in `RecordingDelegate`; without it, `RTVIDocumentTests` reports the message as not reaching the app.
