import Foundation
#if canImport(os)
import os.log
#endif

/// Log level used for logging by the framework.
public enum LogLevel: UInt8 {
    /// A level lower than all log levels.
    case off = 0
    /// Corresponds to the `.error` log level.
    case error = 1
    /// Corresponds to the `.warn` log level.
    case warn = 2
    /// Corresponds to the `.debug` log level.
    case debug = 4
    /// Corresponds to the `.info` log level.
    case info = 3
    /// Corresponds to the `.trace` log level.
    case trace = 5
}

#if canImport(os)
extension LogLevel {
    fileprivate var logType: OSLogType? {
        switch self {
        case .off:
            return nil
        case .error:
            return .error
        case .warn:
            return .default
        case .info:
            return .info
        case .debug:
            return .debug
        case .trace:
            return .debug
        }
    }
}
#endif

/// Sets the log level for logs produce by the framework.
public func setLogLevel(_ logLevel: LogLevel) {
    Logger.shared.setLogLevel(logLevel: logLevel)
}

internal final class Logger {
    fileprivate var level: LogLevel = .warn

    #if canImport(os)
    fileprivate let osLog: OSLog = .init(subsystem: "co.daily.rtvi", category: "main")
    #endif

    internal static let shared: Logger = .init()

    public func setLogLevel(logLevel: LogLevel) {
        self.level = logLevel
    }

    @inlinable
    internal func error(_ message: @autoclosure () -> String) {
        self.log(.error, message())
    }

    @inlinable
    internal func warn(_ message: @autoclosure () -> String) {
        self.log(.warn, message())
    }

    @inlinable
    internal func info(_ message: @autoclosure () -> String) {
        self.log(.info, message())
    }

    @inlinable
    internal func debug(_ message: @autoclosure () -> String) {
        self.log(.debug, message())
    }

    @inlinable
    internal func trace(_ message: @autoclosure () -> String) {
        self.log(.trace, message())
    }

    @inlinable
    internal func log(_ level: LogLevel, _ message: @autoclosure () -> String) {
        guard self.level.rawValue >= level.rawValue else {
            return
        }

        guard self.level != .off else {
            return
        }

        #if canImport(os)
        let log = self.osLog

        // The following force-unwrap is okay since we check for `.off` above:
        // swiftlint:disable:next force_unwrapping
        let type = level.logType!

        os_log("%@", log: log, type: type, message())
        #else
        // Platforms without `os`, such as Linux.
        FileHandle.standardError.write(Data("[PipecatClientIOS] [\(level)] \(message())\n".utf8))
        #endif
    }
}
