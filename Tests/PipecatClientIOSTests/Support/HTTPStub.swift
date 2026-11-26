import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Answers the requests `URLSession.shared` makes, while installed, and records them with their bodies.
final class HTTPStub: URLProtocol {
    struct Response {
        let status: Int
        let body: JSON
    }

    nonisolated(unsafe) private(set) static var requests: [(request: URLRequest, body: Data)] = []
    nonisolated(unsafe) private static var responses: [String: Response] = [:]

    /// Answers requests to a URL with a response, until `uninstall()`.
    static func install(_ responses: [String: Response]) {
        self.responses = responses
        requests = []
        URLProtocol.registerClass(HTTPStub.self)
    }

    static func uninstall() {
        URLProtocol.unregisterClass(HTTPStub.self)
        responses = [:]
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.requests.append((request, Self.body(of: request)))
        let url = request.url!
        let answer = Self.responses[url.absoluteString] ?? Response(status: 404, body: "Not found")
        let response = HTTPURLResponse(url: url, statusCode: answer.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: (try? JSONEncoder().encode(answer.body)) ?? Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// A request's body, which reaches a `URLProtocol` as a stream.
    private static func body(of request: URLRequest) -> Data {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return Data()
        }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        stream.open()
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 {
                break
            }
            data.append(buffer, count: count)
        }
        stream.close()
        return data
    }
}
