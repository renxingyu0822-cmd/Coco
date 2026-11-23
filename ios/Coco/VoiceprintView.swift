//
//  VoiceprintView.swift
//  Coco
//
//  Settings → Voice fingerprint.
//    1. Set up: you read 3 sentences, the server makes your fingerprint (server/app/voiceprint.py)
//    2. "Is it me?": say anything, see if Coco recognises you + the score (for tuning)
//    3. Delete it
//
//  Records WAV (not m4a), stops by itself when you pause, like voice chat.
//

import SwiftUI

struct VoiceprintView: View {
    // what you read out loud when setting up (different sounds = better fingerprint)
    private let sentences = [
        "Good morning, Coco. I slept well and I'm looking forward to a cup of tea.",
        "Please remind me to call my daughter this evening after dinner.",
        "The weather is lovely today, so I might go for a walk in the park.",
    ]

    enum Step: Equatable {
        case loading               // asking the server "is a fingerprint saved?"
        case idle
        case recording(Int)        // reading sentence number n (0, 1, 2)
        case saving
        case testing               // listening for "Is it me?"
        case checking              // waiting for the score
    }

    @State private var step = Step.loading
    @State private var enrolled = false
    @State private var setupClips: [URL] = []
    @State private var result: ChatService.VoiceCheck?
    @State private var message: String?            // errors / hints, shown in red
    @State private var confirmDelete = false
    @State private var recorder = VoiceRecorder(wav: true)

    private var busy: Bool { step != .idle }

    var body: some View {
        Form {
            Section {
                statusRow
            } footer: {
                Text("Coco keeps a voice fingerprint (a list of numbers), never the recording itself. "
                     + "It's used so Coco only remembers things you said, not the TV or visitors. "
                     + "You can delete it any time.")
            }

            if case .recording(let n) = step {
                recordingSection(n)
            } else {
                Section {
                    Button(enrolled ? "Record my voice again" : "Set up my voice") { startSetup() }
                        .disabled(busy)
                }
            }

            if enrolled {
                testSection
                Section {
                    Button("Delete my voice fingerprint", role: .destructive) { confirmDelete = true }
                        .disabled(busy)
                }
            }

            if let message {
                Section { Text(message).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Voice fingerprint")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete your voice fingerprint?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
        }
        .task { await loadStatus() }
        .onDisappear { recorder.cancel() }   // leaving the screen = stop the mic
    }

    // ── pieces of the screen ──

    @ViewBuilder private var statusRow: some View {
        switch step {
        case .loading:
            Label("Checking…", systemImage: "hourglass").foregroundStyle(.secondary)
        case .saving:
            Label("Saving your fingerprint… (first time can take ~30 s)", systemImage: "hourglass")
                .foregroundStyle(.secondary)
        default:
            if enrolled {
                Label("Your voice is set up", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            } else {
                Label("Not set up yet", systemImage: "waveform").foregroundStyle(.secondary)
            }
        }
    }

    private func recordingSection(_ n: Int) -> some View {
        Section {
            Text("“\(sentences[n])”")
                .font(.title3)
                .padding(.vertical, 6)
            Label("Listening… read it out loud, then pause", systemImage: "mic.fill")
                .foregroundStyle(.red)
            Button("Cancel", role: .cancel) { recorder.cancel() }
        } header: {
            Text("Sentence \(n + 1) of \(sentences.count)")
        }
    }

    private var testSection: some View {
        Section {
            Button(step == .testing ? "Listening… say something" : "Is it me?") { test() }
                .disabled(busy)

            if step == .checking {
                Label("Checking…", systemImage: "hourglass").foregroundStyle(.secondary)
            } else if let r = result {
                Label(r.is_you ? "That's you" : "Not you",
                      systemImage: r.is_you ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(r.is_you ? .green : .red)
                    .font(.title3.bold())
                Text("Score \(r.score, specifier: "%.2f")  (needs \(r.threshold, specifier: "%.2f") or more)")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Test")
        } footer: {
            Text("Try it yourself, then let someone else (or the TV) try.")
        }
    }

    // ── what the buttons do ──

    private func loadStatus() async {
        do {
            enrolled = try await ChatService.voiceprintEnrolled()
            message = nil
        } catch {
            message = "Can't reach the server: \(error.localizedDescription)"
        }
        step = .idle
    }

    // record one clip; nil if cancelled or nobody spoke
    private func record() async -> URL? {
        guard await recorder.askPermission() else {
            message = "Coco needs the microphone. Allow it in Settings → Apps → Coco."
            return nil
        }
        do {
            switch try await recorder.listen() {
            case .spoke: return recorder.fileURL
            case .silent: message = "I didn't hear anything. Try again a bit louder."
            case .cancelled: break
            }
        } catch {
            message = "Recording failed: \(error.localizedDescription)"
        }
        return nil
    }

    private func startSetup() {
        message = nil
        result = nil
        setupClips = []
        Task {
            for n in sentences.indices {
                step = .recording(n)
                guard let clip = await record() else { step = .idle; return }
                // the recorder reuses one file, so keep a copy of each sentence
                let copy = FileManager.default.temporaryDirectory.appendingPathComponent("voiceprint-\(n).wav")
                try? FileManager.default.removeItem(at: copy)
                try? FileManager.default.copyItem(at: clip, to: copy)
                setupClips.append(copy)
            }
            step = .saving
            do {
                try await ChatService.enrollVoiceprint(setupClips)
                enrolled = true
            } catch {
                message = error.localizedDescription
            }
            step = .idle
        }
    }

    private func test() {
        message = nil
        result = nil
        Task {
            step = .testing
            guard let clip = await record() else { step = .idle; return }
            step = .checking
            do {
                result = try await ChatService.checkVoiceprint(clip)
            } catch {
                message = error.localizedDescription
            }
            step = .idle
        }
    }

    private func delete() {
        Task {
            do {
                try await ChatService.deleteVoiceprint()
                enrolled = false
                result = nil
            } catch {
                message = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack { VoiceprintView() }
}
