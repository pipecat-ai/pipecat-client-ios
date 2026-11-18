import Foundation

/// A JSON value, which tells booleans, numbers and null apart, to compare and
/// validate messages as they are on the wire.
enum JSON: Codable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSON])
    case object([String: JSON])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSON].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSON].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    /// The JSON an encodable value encodes to.
    init(encoding value: Encodable) throws {
        let data = try JSONEncoder().encode(AnyEncodable(value))
        self = try JSONDecoder().decode(JSON.self, from: data)
    }

    init(parsing text: String) throws {
        self = try JSONDecoder().decode(JSON.self, from: Data(text.utf8))
    }

    var text: String {
        // swiftlint:disable:next force_try
        String(decoding: try! JSONEncoder().encode(self), as: UTF8.self)
    }

    subscript(key: String) -> JSON? {
        if case .object(let object) = self {
            return object[key]
        }
        return nil
    }

    var string: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    var array: [JSON]? {
        if case .array(let value) = self {
            return value
        }
        return nil
    }

    var object: [String: JSON]? {
        if case .object(let value) = self {
            return value
        }
        return nil
    }

    /// Whether this value has all of `expected`: every field of an object, with
    /// what it has, and every item of an array.
    func carries(_ expected: JSON) -> Bool {
        switch (self, expected) {
        case (.object(let actual), .object(let expected)):
            return expected.allSatisfy { key, value in actual[key]?.carries(value) ?? false }
        case (.array(let actual), .array(let expected)):
            return actual.count == expected.count && zip(actual, expected).allSatisfy { $0.carries($1) }
        default:
            return self == expected
        }
    }
}

private struct AnyEncodable: Encodable {
    let value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

/// Validates JSON against the document's schemas, with the keywords they use.
struct SchemaValidator {
    let schemas: [String: JSON]

    /// What is wrong with a value, by a schema, each with where it is.
    func violations(_ value: JSON, _ schema: JSON, at path: String = "") -> [String] {
        guard let rules = schema.object else {
            return []
        }
        var found: [String] = []

        if let ref = rules["$ref"]?.string {
            let name = String(ref.split(separator: "/").last ?? "")
            guard let target = schemas[name] else {
                return ["\(path) refers to the unknown schema \(ref)"]
            }
            found += violations(value, target, at: path)
        }
        for part in rules["allOf"]?.array ?? [] {
            found += violations(value, part, at: path)
        }
        if let options = rules["anyOf"]?.array,
            !options.contains(where: { violations(value, $0, at: path).isEmpty })
        {
            found.append("\(path) matches none of its schema's options")
        }
        if let excluded = rules["not"], violations(value, excluded, at: path).isEmpty {
            found.append("\(path) matches a schema it must not")
        }
        if let constant = rules["const"], value != constant {
            found.append("\(path) is \(value.text), not \(constant.text)")
        }
        if let values = rules["enum"]?.array, !values.contains(value) {
            found.append("\(path) is \(value.text), not one of \(JSON.array(values).text)")
        }
        if let type = rules["type"]?.string, !Self.matches(value, type: type) {
            found.append("\(path) is \(value.text), not of type \(type)")
        }

        if case .object(let object) = value {
            let properties = rules["properties"]?.object ?? [:]
            for case .string(let key) in rules["required"]?.array ?? [] where object[key] == nil {
                found.append("\(path)/\(key) is required")
            }
            for (key, item) in object {
                if let property = properties[key] {
                    found += violations(item, property, at: "\(path)/\(key)")
                } else if rules["additionalProperties"] == .bool(false) {
                    found.append("\(path)/\(key) isn't allowed")
                } else if let additional = rules["additionalProperties"], additional.object != nil {
                    found += violations(item, additional, at: "\(path)/\(key)")
                }
            }
        }
        if case .array(let items) = value {
            if case .number(let minimum) = rules["minItems"], Double(items.count) < minimum {
                found.append("\(path) has fewer than \(Int(minimum)) items")
            }
            if let itemSchema = rules["items"] {
                for (index, item) in items.enumerated() {
                    found += violations(item, itemSchema, at: "\(path)/\(index)")
                }
            }
        }
        return found
    }

    private static func matches(_ value: JSON, type: String) -> Bool {
        switch (type, value) {
        case ("null", .null), ("boolean", .bool), ("number", .number), ("string", .string),
            ("array", .array), ("object", .object):
            return true
        case ("integer", .number(let number)):
            return number.rounded() == number
        default:
            return false
        }
    }
}
