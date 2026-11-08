//
//  VoiceRecorder.swift
//  Coco
//
//  Records your voice (a small .m4a file) and notices by itself when you've
//  stopped talking, so you never have to press "send" (hands-free mode).
//
//  How it notices: every 0.1 s it checks how loud the mic is.
//    loud            -> you're talking
//    quiet for 1.5 s -> after talking = you're done, stop
//    quiet for 10 s  -> without talking at all = nobody's there, stop
//  Uses Apple's built-in AVAudioRecorder, no extra libraries.
//

import AVFoundation

@MainActor
final class VoiceRecorder {
    enum Result { case spoke, silent, cancelled }

    // ── tuning knobs (we may adjust these after testing in a real room) ──
    var speechLevel: Float = -35      // dB. Louder than this = talking. (0 = max, -60 = very quiet)
    var pauseToFinish: Double = 1.5   // seconds of quiet after talking = done
    var giveUpAfter: Double = 10      // seconds without any talking = stop listening

    private var recorder: AVAudioRecorder?
    private var cancelled = false

    // where the recording goes (a temp file, overwritten each time)
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("coco-recording.m4a")

    // asks for mic permission the first time (iPhone shows the popup once)
    func askPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    // start recording and wait until you're done (or nobody talks, or cancel() is called)
    func listen() async throws -> Result {
        // playAndRecord: we need the mic AND Coco's voice afterwards.
        // defaultToSpeaker: otherwise sound comes from the quiet phone-call earpiece
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
        try session.setActive(true)

        // small file, still clear for speech: AAC, mono, 16 kHz
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        let rec = try AVAudioRecorder(url: fileURL, settings: settings)
        rec.isMeteringEnabled = true      // lets us read the loudness
        recorder = rec
        cancelled = false
        rec.record(forDuration: 60)       // safety: never longer than 60 s

        let began = Date()
        var heardSpeech = false
        var quietSince: Date?

        while true {
            try await Task.sleep(for: .milliseconds(100))

            if cancelled { rec.stop(); return .cancelled }
            if !rec.isRecording { return heardSpeech ? .spoke : .silent }  // hit the 60 s limit

            rec.updateMeters()
            let level = rec.averagePower(forChannel: 0)

            if level > speechLevel {
                heardSpeech = true          // talking
                quietSince = nil
            } else if heardSpeech {
                quietSince = quietSince ?? Date()   // quiet after talking: start the pause clock
                if Date().timeIntervalSince(quietSince!) >= pauseToFinish {
                    rec.stop()
                    return .spoke
                }
            }

            if !heardSpeech && Date().timeIntervalSince(began) >= giveUpAfter {
                rec.stop()
                return .silent
            }
        }
    }

    // stop listening right away (e.g. "End conversation" button)
    func cancel() {
        cancelled = true
        recorder?.stop()
    }
}
