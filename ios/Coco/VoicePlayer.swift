//
//  VoicePlayer.swift
//  Coco
//
//  Plays Coco's voice (the mp3 we get from the server's /speak) and lets us
//  wait until she's finished, so the mic only turns on again after she's done.
//  Uses Apple's built-in AVAudioPlayer, no extra libraries.
//

import AVFoundation

@MainActor
final class VoicePlayer: NSObject, AVAudioPlayerDelegate {
    // keep the player alive while it plays (if it's thrown away, the sound stops)
    private var player: AVAudioPlayer?
    // the "wake me up when she's done" note for whoever is waiting
    private var whenDone: CheckedContinuation<Void, Never>?

    // play and wait until the end (or until stop() is called)
    func play(_ mp3: Data) async {
        stop()  // only one Coco voice at a time
        do {
            // playAndRecord = same setting as the mic uses (no switching back and forth),
            // and it plays even when the silent switch is on (older users may not know about
            // the switch). defaultToSpeaker = loud speaker, not the earpiece.
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio,
                                                            options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)

            let p = try AVAudioPlayer(data: mp3)
            p.delegate = self   // so iOS tells us when she's finished
            player = p
            p.play()
        } catch {
            print("Voice play error:", error)  // no sound, but the text bubble is still there
            return
        }
        await withCheckedContinuation { whenDone = $0 }
    }

    func stop() {
        player?.stop()
        finished()
    }

    // iOS calls this when the audio reaches the end
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.finished() }
    }

    private func finished() {
        whenDone?.resume()
        whenDone = nil
    }
}
