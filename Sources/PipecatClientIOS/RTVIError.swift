import Foundation

/// A protocol representing a base error occurring during an operation.
public protocol RTVIError: Error {
    /// A human-readable description of the error.
    var message: String { get }

    /// If the error was caused by another error, this value is set.
    var underlyingError: Error? { get }
}

extension RTVIError {
    public var underlyingError: Error? { return nil }

    /// Provides a detailed description of the error, including any underlying error.
    public var localizedDescription: String {
        if let underlyingError = self.underlyingError as? RTVIError {
            // Finding the root cause
            var rootCauseError: RTVIError = underlyingError
            while let underlyingError = rootCauseError.underlyingError as? RTVIError {
                rootCauseError = underlyingError
            }
            return "\(message) \(rootCauseError.localizedDescription)"
        } else {
            return message
        }
    }
}

public struct BotAlreadyStartedError: RTVIError {
    public let message: String =
        "Pipecat client has already been started. Please call disconnect() before starting again."
    public let underlyingError: Error?

    public init(underlyingError: Error? = nil) {
        self.underlyingError = underlyingError
    }
}

/// Invalid or malformed auth bundle provided to Transport.
public struct InvalidTransportParamsError: RTVIError {
    public let message: String = "Invalid or malformed transport params provided to Transport."
    public let underlyingError: Error?

    public init(underlyingError: Error? = nil) {
        self.underlyingError = underlyingError
    }
}

/// Failed to fetch the authentication bundle from the RTVI backend.
public struct HttpError: RTVIError {
    public let message: String
    public let underlyingError: Error?

    public init(message: String, underlyingError: Error? = nil) {
        self.underlyingError = underlyingError
        self.message = message
    }
}

/// Failed to fetch the auth bundle.
public struct StartBotError: RTVIError {
    public let message: String = "Failed to start the bot using the specified endpoint."
    public let underlyingError: Error?

    public init(underlyingError: Error? = nil) {
        self.underlyingError = underlyingError
    }
}

/// Bot is not ready yet.
public struct BotNotReadyError: RTVIError {
    public let message: String = "Bot is not ready yet."
    public let underlyingError: Error?

    public init(underlyingError: Error? = nil) {
        self.underlyingError = underlyingError
    }
}

/// Received error response from backend.
public struct BotResponseError: RTVIError {
    public let message: String
    public let underlyingError: Error?

    public init(message: String = "Received error response from backend.", underlyingError: Error? = nil) {
        self.message = message
        self.underlyingError = underlyingError
    }
}

/// The operation timed out before it could complete.
public struct ResponseTimeoutError: RTVIError {
    public let message: String = "The operation timed out before it could complete."
    public let underlyingError: Error?

    public init(underlyingError: Error? = nil) {
        self.underlyingError = underlyingError
    }
}

/// A feature is not supported by the current implementation or source.
public struct UnsupportedFeatureError: RTVIError {
    public let message: String
    public let underlyingError: Error?
    public let feature: String

    public init(
        feature: String,
        source: String? = nil,
        message customMessage: String? = nil,
        underlyingError: Error? = nil
    ) {
        self.feature = feature
        self.underlyingError = underlyingError

        var msg = "\(feature) not supported"
        if let source = source {
            msg = "\(source) does not support \(feature)"
        }

        if let customMessage = customMessage {
            msg += ": \(customMessage)"
        }

        self.message = msg
    }
}

/// Received an error response when trying to execute the function.
public struct AsyncExecutionError: RTVIError {
    public let message: String
    public let underlyingError: Error?

    public init(functionName: String, underlyingError: Error? = nil) {
        self.message = "Received an error response when trying to execute the function \(functionName)."
        self.underlyingError = underlyingError
    }
}

/// An unknown error occurred..
public struct OtherError: RTVIError {
    public let message: String
    public let underlyingError: Error?

    public init(message: String, underlyingError: Error? = nil) {
        self.message = message
        self.underlyingError = underlyingError
    }
}
