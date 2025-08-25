import Foundation

/// Represents an ongoing asynchronous operation.
class Promise<Value> {

    public var onResolve: ((Value) -> Void)?
    public var onReject: ((Error) -> Void)?

    public func resolve(value: Value) {
        self.onResolve?(value)
    }

    public func reject(error: Error) {
        self.onReject?(error)
    }
}
