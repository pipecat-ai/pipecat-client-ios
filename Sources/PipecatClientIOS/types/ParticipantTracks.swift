import Foundation

/// Media tracks associated with a participant.
public struct ParticipantTracks: Equatable {
    public let audio: MediaStreamTrack?
    public let video: MediaStreamTrack?
    public let screenAudio: MediaStreamTrack?
    public let screenVideo: MediaStreamTrack?

    public init(
        audio: MediaStreamTrack?,
        video: MediaStreamTrack?,
        screenAudio: MediaStreamTrack?,
        screenVideo: MediaStreamTrack?
    ) {
        self.audio = audio
        self.video = video
        self.screenAudio = screenAudio
        self.screenVideo = screenVideo
    }
}
