import Foundation

public struct MediaStreamTrack: Hashable, Equatable {

    public enum Kind: String, CaseIterable {
        case audio = "audio"
        case video = "video"
    }

    public let id: MediaTrackId
    public let kind: Kind

    public init(id: MediaTrackId, kind: Kind) {
        self.id = id
        self.kind = kind
    }

}
