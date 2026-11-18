#!/usr/bin/env python3
#
# Copyright (c) 2026, Daily.
#
# SPDX-License-Identifier: BSD-2-Clause
#

"""Generates the RTVI protocol's Swift types from its AsyncAPI document.

Pipecat publishes an AsyncAPI document for each RTVI protocol version. The one
for the version `rtviProtocolVersion` names, in `PipecatClientVersion.swift`, is
kept in `spec/<version>/rtvi.asyncapi.json`, and this script writes
`Sources/PipecatClientIOS/generated/RTVIProtocol.swift` from it.

    python3 scripts/rtvi_protocol.py sync [--ref <git ref> | --pipecat <path>]
        Copies the version's document from Pipecat, then generates: from the
        pipecat-ai/pipecat repository at a ref, `main` unless one is given, or
        from a local Pipecat checkout.
    python3 scripts/rtvi_protocol.py generate
        Writes the generated file from the kept document.
    python3 scripts/rtvi_protocol.py check
        Fails when the generated file isn't what the kept document produces.

It runs on the Python that ships with Xcode's command line tools, 3.9.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import textwrap
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "Sources" / "PipecatClientIOS" / "generated" / "RTVIProtocol.swift"
VERSION_FILE = ROOT / "Sources" / "PipecatClientIOS" / "PipecatClientVersion.swift"
PIPECAT_SPEC = "src/pipecat/processors/frameworks/rtvi/spec"
SCHEMAS = "#/components/schemas/"
LINE_LENGTH = 120

# Messages the client doesn't handle or send, whose types aren't generated. The
# UI messages describe and drive the elements of a web page.
SKIPPED_MESSAGES = {
    "raw-audio",
    "raw-audio-batch",
    "ui-cancel-job-group",
    "ui-command",
    "ui-event",
    "ui-job-group",
    "ui-snapshot",
}

# Schemas whose public type is hand-written, by the type's name. Their fields
# can't follow the document's: they keep a type's fields optional, its
# initializer, or a fallback for older bots.
HAND_WRITTEN = {
    "BotOutputMessageData": "BotOutputData",
    "LLMFunctionCallMessageData": "LLMFunctionCallData",
    "SendTextOptions": "SendTextOptions",
    "UserTranscriptionMessageData": "Transcript",
}

# Public names that don't follow from the schema's: the SDK's names from before
# its types were generated, and `BotOutputType`, client-js's name.
TYPE_NAMES = {
    "ErrorData": "BotError",
    "ErrorResponseData": "ErrorResponse",
    "MetricsMessageData": "PipecatMetrics",
    "RawServerResponseData": "ClientMessageData",
    "TextMessageData": "BotLLMText",
    "TextType": "BotOutputType",
}

# Field names that don't follow from the property's, kept from the SDK's names.
FIELD_NAMES = {
    "tool_call_id": "toolCallID",
}

# Names of enums declared for a property, where its name isn't one: `Type` is
# the name of a type's metatype.
ENUM_NAMES = {
    "type": "SourceType",
}

# Types only client messages use that apps build too; the other client-message
# types are internal.
PUBLIC_CLIENT_TYPES = {"File", "FileBytes", "FileUrl", "KeypadEntry", "SendFileOptions"}

# Names of the keypad's keys, which aren't Swift identifiers.
KEY_NAMES = {
    "0": "zero",
    "1": "one",
    "2": "two",
    "3": "three",
    "4": "four",
    "5": "five",
    "6": "six",
    "7": "seven",
    "8": "eight",
    "9": "nine",
    "#": "pound",
    "*": "star",
}

KEYWORDS = {
    "as", "break", "case", "catch", "class", "continue", "default", "defer", "do", "else",
    "enum", "extension", "fallthrough", "false", "for", "func", "guard", "if", "import",
    "in", "init", "internal", "is", "let", "nil", "operator", "private", "protocol",
    "public", "repeat", "return", "self", "static", "struct", "subscript", "super",
    "switch", "throw", "throws", "true", "try", "var", "where", "while",
}  # fmt: skip


class GenerationError(Exception):
    pass


def protocol_version() -> str:
    match = re.search(r'rtviProtocolVersion = "([^"]+)"', VERSION_FILE.read_text())
    if not match:
        raise GenerationError(f"rtviProtocolVersion not found in {VERSION_FILE.relative_to(ROOT)}")
    return match.group(1)


def document_path(version: str) -> Path:
    return ROOT / "spec" / version / "rtvi.asyncapi.json"


def camel(name: str, upper: bool = False) -> str:
    words = [word for word in re.split(r"[^A-Za-z0-9]+", name) if word]
    result = "".join(word[:1].upper() + word[1:] for word in words)
    return result if upper else result[:1].lower() + result[1:]


def identifier(name: str) -> str:
    return f"`{name}`" if name in KEYWORDS else name


def string_literal(text: str) -> str:
    return json.dumps(text, ensure_ascii=False)


def ref_name(schema: dict) -> str | None:
    """The schema a `$ref`, or an `allOf` holding only one, points at."""
    if "$ref" in schema:
        return schema["$ref"].removeprefix(SCHEMAS)
    if len(schema.get("allOf", [])) == 1:
        return ref_name(schema["allOf"][0])
    return None


def allows_anything(schema: dict) -> bool:
    constraints = ("type", "$ref", "anyOf", "allOf", "oneOf", "const", "enum", "properties", "items")
    return not any(keyword in schema for keyword in constraints)


class Generator:
    def __init__(self, document: dict):
        self.document = document
        self.schemas = document["components"]["schemas"]
        self.server_schemas = self._reachable("sendServerMessages")
        self.client_schemas = self._reachable("receiveClientMessages") - self.server_schemas

    def _reachable(self, operation: str) -> set[str]:
        """The schemas the operation's messages use, except the skipped messages'."""
        found: set[str] = set()

        def walk(value):
            if isinstance(value, dict):
                name = value.get("$ref", "").removeprefix(SCHEMAS)
                if name and name in self.schemas and name not in found:
                    found.add(name)
                    walk(self.schemas[name])
                for item in value.values():
                    walk(item)
            elif isinstance(value, list):
                for item in value:
                    walk(item)

        messages = self.document["components"]["messages"]
        for ref in self.document["operations"][operation]["messages"]:
            message = messages[ref["$ref"].split("/")[-1]]
            if message["name"] not in SKIPPED_MESSAGES:
                walk(message["payload"])
        return found

    def type_name(self, schema_name: str) -> str:
        if schema_name in HAND_WRITTEN:
            return HAND_WRITTEN[schema_name]
        if schema_name in TYPE_NAMES:
            return TYPE_NAMES[schema_name]
        return re.sub(r"MessageData$", "Data", schema_name)

    def access(self, schema_name: str) -> str:
        if schema_name in self.server_schemas or schema_name in PUBLIC_CLIENT_TYPES:
            return "public"
        return "internal"

    # Swift types

    def swift_type(self, schema: dict, owner: str, field: str, nested: list[list[str]]) -> tuple[str, bool]:
        """A property's Swift type, and whether the schema allows null.

        A type the property needs of its own, such as an enum, is added to
        `nested`, to be declared inside its owner's.
        """
        name = ref_name(schema)
        if name:
            return self.type_name(name), False
        if "anyOf" in schema:
            options = [option for option in schema["anyOf"] if option.get("type") != "null"]
            nullable = len(options) < len(schema["anyOf"])
            if len(options) == 1:
                swift, _ = self.swift_type(options[0], owner, field, nested)
                return swift, nullable
            if any(allows_anything(option) or option.get("type") == "object" for option in options):
                return "Value", nullable
            refs = [ref_name(option) for option in options]
            if all(refs):
                enums = [ref for ref in refs if "enum" in self.schemas[ref]]
                # An open enum takes the strings beside it.
                if len(enums) == 1 and all(o.get("type") == "string" for o in options if not ref_name(o)):
                    return self.type_name(enums[0]), nullable
                if not enums:
                    union = camel(field, upper=True)
                    nested.append(self.union(union, [self.type_name(ref) for ref in refs]))
                    return union, nullable
            if all(option.get("type") == "string" or ref_name(option) for option in options):
                enums = [ref_name(o) for o in options if ref_name(o)]
                if len(enums) == 1 and "enum" in self.schemas[enums[0]]:
                    return self.type_name(enums[0]), nullable
            raise GenerationError(f"{owner}.{field}: unsupported anyOf {json.dumps(schema['anyOf'])}")
        if allows_anything(schema):
            return "Value", False
        if "enum" in schema:
            enum = ENUM_NAMES.get(field) or camel(field, upper=True)
            # The schema's description is the property's.
            nested.append(self.open_enum(enum, schema, "public", described=False))
            return enum, False
        kind = schema.get("type")
        if kind == "string":
            return "String", False
        if kind == "integer":
            return "Int", False
        if kind == "number":
            return "Double", False
        if kind == "boolean":
            return "Bool", False
        if kind == "array":
            if "items" not in schema:
                return "[Value]", False
            item, _ = self.swift_type(schema["items"], owner, field, nested)
            return f"[{item}]", False
        if kind == "object" and "properties" not in schema:
            return "Value", False
        raise GenerationError(f"{owner}.{field}: unsupported schema {json.dumps(schema)}")

    # Declarations

    def doc_comment(self, text: str | None, indent: str) -> list[str]:
        if not text:
            return []
        width = LINE_LENGTH - len(indent) - 4
        lines = []
        for paragraph in text.strip().split("\n"):
            wrapped = textwrap.wrap(paragraph, width, break_long_words=False, break_on_hyphens=False)
            lines += [f"{indent}/// {line}" for line in wrapped] or [f"{indent}///"]
        return lines

    def open_enum(self, name: str, schema: dict, access: str, described: bool = True) -> list[str]:
        """An enum as a struct of its values, which also takes values it doesn't name."""
        lines = self.doc_comment(schema.get("description"), "") if described else []
        lines += [
            f"{access} struct {name}: RawRepresentable, Codable, Hashable {{",
            f"    {access} let rawValue: String",
            "",
            f"    {access} init(rawValue: String) {{",
            "        self.rawValue = rawValue",
            "    }",
            "",
        ]
        for value in schema["enum"]:
            member = KEY_NAMES.get(value) or camel(value)
            lines.append(f"    {access} static let {identifier(member)} = {name}(rawValue: {string_literal(value)})")
        lines.append("}")
        return lines

    def union(self, name: str, cases: list[str]) -> list[str]:
        """A value of one of several types, decoded as the first that takes it."""
        lines = [f"public enum {name}: Codable, Equatable {{"]
        lines += [f"    case {camel(case)}({case})" for case in cases]
        lines += ["", "    public init(from decoder: Decoder) throws {"]
        for case in cases:
            lines += [
                f"        if let value = try? {case}(from: decoder) {{",
                f"            self = .{camel(case)}(value)",
                "            return",
                "        }",
            ]
        description = string_literal(f"Not any of {', '.join(cases)}")
        lines += [
            "        throw DecodingError.dataCorrupted(",
            f"            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: {description})",
            "        )",
            "    }",
            "",
            "    public func encode(to encoder: Encoder) throws {",
            "        switch self {",
        ]
        for case in cases:
            lines += [f"        case .{camel(case)}(let value):", "            try value.encode(to: encoder)"]
        lines += ["        }", "    }", "}"]
        return lines

    def struct(self, schema_name: str) -> list[str]:
        schema = self.schemas[schema_name]
        name = self.type_name(schema_name)
        access = self.access(schema_name)
        if "enum" in schema:
            return self.open_enum(name, schema, access)

        required = set(schema.get("required", []))
        nested: list[list[str]] = []
        fields = []
        for prop, prop_schema in schema.get("properties", {}).items():
            swift, nullable = self.swift_type(prop_schema, name, prop, nested)
            optional = nullable or prop not in required
            fields.append(
                {
                    "key": prop,
                    "name": FIELD_NAMES.get(prop) or camel(prop),
                    "type": swift + ("?" if optional else ""),
                    "optional": optional,
                    "description": prop_schema.get("description"),
                }
            )

        lines = self.doc_comment(schema.get("description"), "")
        lines.append(f"{access} struct {name}: Codable, Equatable {{")
        for declaration in nested:
            lines += ["    " + line if line else "" for line in declaration] + [""]
        for field in fields:
            lines += self.doc_comment(field["description"], "    ")
            lines.append(f"    {access} let {identifier(field['name'])}: {field['type']}")

        if any(field["name"] != field["key"] for field in fields):
            lines += ["", "    enum CodingKeys: String, CodingKey {"]
            for field in fields:
                key = field["name"]
                suffix = f" = {string_literal(field['key'])}" if key != field["key"] else ""
                lines.append(f"        case {identifier(key)}{suffix}")
            lines.append("    }")

        # Required parameters first, so the optional ones can be left out.
        ordered = [f for f in fields if not f["optional"]] + [f for f in fields if f["optional"]]
        parameters = [f"{f['name']}: {f['type']}" + (" = nil" if f["optional"] else "") for f in ordered]
        signature = f"    {access} init({', '.join(parameters)}) {{"
        if access == "internal" and not any(f["optional"] for f in fields):
            # The synthesized initializer is the same.
            lines.append("}")
            return lines
        lines.append("")
        if not fields:
            lines.append(f"    {access} init() {{}}")
        else:
            if len(signature) <= LINE_LENGTH:
                lines.append(signature)
            else:
                lines.append(f"    {access} init(")
                lines += [f"        {parameter}," for parameter in parameters[:-1]]
                lines += [f"        {parameters[-1]}", "    ) {"]
            lines += [f"        self.{f['name']} = {identifier(f['name'])}" for f in fields]
            lines.append("    }")
        lines.append("}")
        return lines

    def generate(self, version: str) -> str:
        names = [
            name
            for name in self.schemas
            if (name in self.server_schemas or name in self.client_schemas) and name not in HAND_WRITTEN
        ]
        lines = [
            f"// Generated by scripts/rtvi_protocol.py from spec/{version}/rtvi.asyncapi.json.",
            "// Don't edit it: run `python3 scripts/rtvi_protocol.py generate`.",
            "// swiftlint:disable all",
            "",
            "import Foundation",
        ]
        for name in sorted(names, key=self.type_name):
            lines += [""] + self.struct(name)
        # Internal is the default access level, which the SDK leaves unwritten.
        return re.sub(r"^( *)internal ", r"\1", "\n".join(lines) + "\n", flags=re.MULTILINE)


def generate() -> str:
    version = protocol_version()
    path = document_path(version)
    if not path.exists():
        raise GenerationError(f"{path.relative_to(ROOT)} not found: run `sync` first")
    return Generator(json.loads(path.read_text())).generate(version)


def sync(ref: str | None, pipecat: str | None):
    version = protocol_version()
    spec = f"{PIPECAT_SPEC}/{version}/rtvi.asyncapi.json"
    if pipecat:
        text = (Path(pipecat) / spec).read_text()
    else:
        url = f"https://raw.githubusercontent.com/pipecat-ai/pipecat/{ref or 'main'}/{spec}"
        try:
            with urllib.request.urlopen(url) as response:
                text = response.read().decode()
        except OSError as error:
            raise GenerationError(f"Couldn't fetch {url}: {error}") from error
    path = document_path(version)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    print(f"Copied the protocol {version} document to {path.relative_to(ROOT)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    sync_command = commands.add_parser("sync")
    source = sync_command.add_mutually_exclusive_group()
    source.add_argument("--ref")
    source.add_argument("--pipecat")
    commands.add_parser("generate")
    commands.add_parser("check")
    args = parser.parse_args()

    try:
        if args.command == "sync":
            sync(args.ref, args.pipecat)
        if args.command in ("sync", "generate"):
            OUTPUT.parent.mkdir(parents=True, exist_ok=True)
            OUTPUT.write_text(generate())
            print(f"Wrote {OUTPUT.relative_to(ROOT)}")
        elif args.command == "check":
            if not OUTPUT.exists() or OUTPUT.read_text() != generate():
                raise GenerationError(
                    f"{OUTPUT.relative_to(ROOT)} is out of date: run `python3 scripts/rtvi_protocol.py generate`"
                )
            print(f"{OUTPUT.relative_to(ROOT)} is up to date")
    except GenerationError as error:
        sys.exit(f"error: {error}")


if __name__ == "__main__":
    main()
