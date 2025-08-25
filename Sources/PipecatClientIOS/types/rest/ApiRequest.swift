import Foundation

public struct APIRequest: Codable {
    public let endpoint: URL

    /// Custom HTTP headers to be sent with the POST request to baseUrl.
    public let headers: [[String: String]]

    /// Custom parameters to add to the auth request body.
    public let requestData: Value?

    public let timeout: TimeInterval?

    public init(
        endpoint: URL,
        headers: [[String: String]] = [],
        requestData: Value? = nil,
        timeout: TimeInterval? = nil
    ) {
        self.endpoint = endpoint
        self.headers = headers
        self.requestData = requestData
        self.timeout = timeout
    }

}
