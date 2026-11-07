//
//  VoicePlayer.swift
//  Coco
//
//  Plays Coco's voice (the mp3 we get from the server's /speak).
//  Uses Apple's built-in AVAudioPlayer, no extra libraries.
//

import AVFoundation

@MainActor
final class VoicePlayer {
    // keep the player alive while it plays (if it's thrown away, the sound stops)
    private var player: AVAudioPlayer?

    func play(_ mp3: Data) {
        do {
            // playAndRecord = same setting as the mic uses (no switching back and forth),
            // and like .playback it plays even when the silent switch is on (older users may
            // not know about the switch). defaultToSpeaker = loud speaker, not the earpiece.
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio,
                                                            options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(data: mp3)
            player?.play()
        } catch {
            print("Voice play error:", error)  // no sound, but the text bubble is still there
        }
    }

    func stop() {
        player?.stop()
    }
}
