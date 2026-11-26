import Foundation

extension RTVIFile {
    /// A file sent with its content.
    ///
    /// - Parameters:
    ///   - data: The file's content.
    ///   - format: The file's MIME type, such as `image/png` or `application/pdf`.
    ///   - name: The file's name.
    public init(data: Data, format: String, name: String? = nil) {
        self.init(format: format, source: .fileBytes(FileBytes(bytes: data.base64EncodedString())), name: name)
    }

    /// A file the bot fetches from a URL.
    ///
    /// - Parameters:
    ///   - url: The file's URL: an `http(s)` URL, a cloud-storage URI such as `s3://`, or what the bot's
    ///     upload endpoint returned.
    ///   - format: The file's MIME type, such as `image/png` or `application/pdf`.
    ///   - name: The file's name.
    public init(url: String, format: String, name: String? = nil) {
        self.init(format: format, source: .fileUrl(FileUrl(url: url)), name: name)
    }
}
