//
//  VoiceRecorder.swift
//  Coco
//
//  Records your voice when you tap the mic (saved as a small .m4a file),
//  so we can send it to the server's /transcribe.
//  Uses Apple's built-in AVAudioRecorder, no extra libraries.
//

import AVFoundation

@MainActor
final class VoiceRecorder {
    private var recorder: AVAudioRecorder?

    // where the recording goes (a temp file, overwritten each time)
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("coco-recording.m4a")

    // asks for mic permission the first time (iPhone shows the popup once)
    func askPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func start() throws {
        // playAndRecord: we need the mic AND want Coco's voice afterwards.
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
        recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder?.record(forDuration: 60)  // safety: stops by itself after 60 s
    }

    // stops and tells us how long it was (very short = probably a mis-tap)
    func stop() -> TimeInterval {
        let length = recorder?.currentTime ?? 0
        recorder?.stop()
        return length
    }
}
