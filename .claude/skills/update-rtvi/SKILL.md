---
name: update-rtvi
description: Bring the iOS SDK up to a new RTVI protocol version that Pipecat released, from syncing its AsyncAPI document to handling every change it brings
---

Bring the SDK up to a new version of the RTVI protocol. Pipecat publishes an AsyncAPI document for each protocol version; the SDK keeps the one for the version it speaks and generates its protocol types from it. This skill syncs the new document, lists what changed, and carries each change through the SDK the way the existing messages are handled.

`AGENTS.md` describes the document, the generator and the tests that check the SDK against it. Read its "Protocol document" and "Protocol tests" entries first.

## Arguments

```
/update-rtvi [VERSION]
```

- `VERSION` (optional): the protocol version to move to, such as `2.4.0`. Without it, use the newest version in Pipecat's `released.json`.

## Instructions

### Step 1: Find the version

Read the protocol versions Pipecat has released, with the Pipecat release that first shipped each:

```bash
curl -s https://raw.githubusercontent.com/pipecat-ai/pipecat/main/src/pipecat/processors/frameworks/rtvi/spec/released.json
```

Compare with `rtviProtocolVersion` in `Sources/PipecatClientIOS/PipecatClientVersion.swift`. When the SDK already speaks the newest version, or `VERSION`, stop and say so.

A version that isn't in `released.json` hasn't shipped, and its document can still change: only move to it if the developer asks, syncing from `main`.

### Step 2: Sync the document

Keep the current document for the comparison in Step 3, then bump the version and sync from the Pipecat release that shipped it (its `pipecat` value, as a tag: `1.18.0` is `v1.18.0`):

```bash
cp spec/<old>/rtvi.asyncapi.json /tmp/rtvi-<old>.json
# set rtviProtocolVersion in PipecatClientVersion.swift to <new>
python3 scripts/rtvi_protocol.py sync --ref v<pipecat release>
git rm -r spec/<old>
```

The sync writes `spec/<new>/rtvi.asyncapi.json` and regenerates `Sources/PipecatClientIOS/generated/RTVIProtocol.swift`. The SDK keeps only the document of the version it speaks.

When the generator stops on a schema it doesn't support, extend `scripts/rtvi_protocol.py` rather than working around it, keeping it to Python 3.9 and the standard library.

### Step 3: List what changed

Compare the two documents and list each change a client sees, by kind:

- **Messages** added or removed, by direction (`receiveClientMessages` is what clients send, `sendServerMessages` what the server sends).
- **Fields** added, removed, or made optional or required; enum and `const` values added.
- **Deprecations**: a message's `x-rtvi-deprecated`, a field's `deprecated: true`.
- **Gating**: a message's `x-rtvi-min-client-version` and `x-rtvi-enabled-by`.
- **Behaviors**: entries of `x-rtvi-behaviors` added or changed.

A short script that loads both documents and compares `components.messages`, `components.schemas` and `x-rtvi-behaviors` is the reliable way; don't eyeball a diff of the JSON. Also read `git diff` of the generated file: a renamed or retyped public property there is a source break for apps. Show the list to the developer before editing anything.

### Step 4: Let the tests point at the work

```bash
xcodebuild test -scheme PipecatClientIOS -destination 'platform=iOS Simulator,name=iPhone 16'
```

`RTVIDocumentTests` fails for each server message the SDK doesn't hand to the app, for each message type it names that the document doesn't have, and for each message it sends that no longer matches its schema. A build error names each hand-written type or use of a generated type that the new types no longer fit.

Every failure should be on the Step 3 list. One that isn't means the list missed a change: go back to Step 3.

### Step 5: Carry each change through

Follow the code that already handles the same kind of change.

**A new server message.** Agree on its delegate method's name and data type with the developer first; they're public API. Name it as client-js names its callback, in the SDK's casing (`onBotLlmMarker` for client-js's `onBotLlmMarker`). Then add:

- its `MessageType` constant in `transport/RTVIMessageInbound.swift`;
- its delegate method, with an empty default in the protocol extension, in `PipecatClientDelegate.swift`. Its doc comment says what the message means, and, for a message with `x-rtvi-enabled-by`, that the bot sends it only when enabled, naming the setting. `onUserAudioLevel` and `onSystemLog` are examples;
- its `case` in `PipecatClient`'s `onMessage`, decoding the generated type, or a public alias of it when the generated name doesn't say what the message is (`SystemLog = TextMessageData`);
- its recording in `Tests/PipecatClientIOSTests/Support/RecordingDelegate.swift`.

To leave a message out instead, list it in `ignored` in `RTVIDocumentTests` with the reason, only when the developer decides so.

**A new client message.** Agree on the public method with the developer first. A bot older than the new version doesn't accept it, so the method throws `UnsupportedFeatureError` for one, checking `botSupports(major:minor:)` as `sendFile` does. Add its builder to `transport/RTVIMessageOutbound.swift`, and add the type it takes to `PUBLIC_CLIENT_TYPES` in the generator when apps build it. Test both cases, and send it in `testMessagesTheClientSendsMatchTheirSchemas`, which checks it against its schema; take it off `notSent`.

**A new field in an existing message.** A generated type has it already. A hand-written one (`HAND_WRITTEN` in the generator, such as `BotOutputData`) gets it added, with its description from the document. A field only newer bots send is optional, since older bots leave it out.

**A field the new version removes or tightens.** Older bots still send the old form, so the type keeps reading it: a hand-written type with a custom `init(from:)` that falls back to the old field, as `BotOutputData` reads `aggregated_by` and `text_type` into `outputType`. Move the type to `HAND_WRITTEN` when it was generated.

**A renamed type or property.** Keep the SDK's public name with `TYPE_NAMES` or `FIELD_NAMES`, or keep the old name as a deprecated alias of the new one, so apps keep compiling.

**A deprecated message or field.** Mark the delegate method (in the protocol and its default) and the property `@available(*, deprecated, message:)`, naming the replacement. Give the `MessageType` constant a "Deprecated:" note in its doc comment instead, since the client's own `switch` uses it. Keep handling it: older bots still send it.

**A new or changed behavior.** Read its description and check the client code that relies on it, such as `MessageDispatcher` for answers carrying a request's `id`. Change the code only when the behavior asks something new of the client.

### Step 6: Verify

```bash
python3 scripts/rtvi_protocol.py check
xcodebuild test -scheme PipecatClientIOS -destination 'platform=iOS Simulator,name=iPhone 16'
docker run --rm -v "$PWD":/src -w /src swift:6.0 swift test
swift-format lint <changed files>
```

When a test fails, find out what it means before changing it. In particular, don't move a message into `ignored`, `notInDocument` or `notSent` to make a test pass.

### Step 7: Changelog and summary

Add the changes under `# Unreleased` in `CHANGELOG.md`: each new delegate method or method under `### Added`, each deprecation under `### Deprecated`, and each source break under `### Changed`, marked ⚠️ with what an app changes.

Then report, for the PR:

```markdown
## RTVI protocol <old> → <new>

- **Changes**: <the Step 3 list>.
- **iOS SDK**: <each change and how the SDK handles it: new delegate methods, new methods, fields, deprecations>.
- **Left out**: <messages added to `ignored`, with the developer's reason, or "none">.
```

## Guardrails

- Never edit `spec/` or `Sources/PipecatClientIOS/generated/` by hand: sync and regenerate.
- Never drop support for older bots: their fields, messages and fallbacks stay.
- Never add public API (a delegate method, method or type) without the developer agreeing to its name and shape.
- Never move a message into `ignored`, `notInDocument` or `notSent` without the developer's decision and a stated reason.

## Checklist

- [ ] The version was found in Pipecat's `released.json`, and the document synced from the release that shipped it
- [ ] Every change between the two documents was listed by kind before any edit
- [ ] Every test failure and build error matched a listed change
- [ ] Each new server message has its constant, delegate method with a default, `onMessage` case and recording
- [ ] Each new client message has a method that checks the bot's version, and is checked against its schema
- [ ] Deprecations are marked, with their replacement, and older bots still work
- [ ] The generated file is up to date, and the tests pass on the simulator and on Linux
- [ ] The changelog and the summary are written
