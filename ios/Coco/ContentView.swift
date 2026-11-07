//
//  ContentView.swift
//  Coco
//
//  Chat screen. Sends messages to our server (ChatService) and shows Coco's replies.
//

import SwiftUI

// one chat bubble
struct ChatMessage: Identifiable {
    let id = UUID()
    let fromUser: Bool
    let text: String
    var isError = false  // error notes are shown, but never sent to the server
}

struct ContentView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(fromUser: false, text: "Hello! I'm Coco. How are you today?")
    ]
    @State private var input = ""
    @State private var waiting = false  // true while Coco is "thinking" (or turning your voice into text)
    @State private var waitingText = "Coco is thinking…"
    @State private var voiceOn = true   // read Coco's replies aloud?
    @State private var voice = VoicePlayer()
    @State private var recorder = VoiceRecorder()
    @State private var recording = false  // true while the mic is listening

    var body: some View {
        VStack(spacing: 0) {
            // header: name in the middle, speaker on/off button on the right
            ZStack {
                Text("Coco")
                    .font(.title.bold())
                HStack {
                    Spacer()
                    Button {
                        voiceOn.toggle()
                        if !voiceOn { voice.stop() }  // turning off also stops her mid-sentence
                    } label: {
                        Image(systemName: voiceOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)  // big enough to hit
                    }
                    .accessibilityLabel(voiceOn ? "Voice on" : "Voice off")
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            Divider()

            // the conversation, jumps to the newest message
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(messages) { msg in
                            Bubble(message: msg).id(msg.id)
                        }
                        if waiting {
                            Bubble(message: ChatMessage(fromUser: false, text: waitingText))
                                .opacity(0.6)
                                .id("thinking")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: waiting) {
                    if waiting { withAnimation { proxy.scrollTo("thinking", anchor: .bottom) } }
                }
            }

            Divider()

            // input row: big mic button + big text field + big send button
            HStack(alignment: .bottom, spacing: 10) {
                // tap once = start listening, tap again = stop and send (tap is easier than holding)
                Button(action: micTapped) {
                    Image(systemName: recording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(recording ? .red : .accentColor)
                }
                .disabled(waiting)
                .accessibilityLabel(recording ? "Stop and send" : "Talk to Coco")

                if recording {
                    // while listening: a clear hint instead of the text field
                    Text("Listening… tap ■ when you're done")
                        .font(.title3)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    TextField("Type a message…", text: $input, axis: .vertical)
                        .font(.title3)
                        .lineLimit(1...4)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                Button(action: { send(trimmed) }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 44))
                }
                .disabled(trimmed.isEmpty || waiting || recording)  // no double sends
                .accessibilityLabel("Send")
            }
            .padding()
        }
    }

    private var trimmed: String { input.trimmingCharacters(in: .whitespacesAndNewlines) }

    // send a message to Coco: used by the send button (typed text) and the mic (spoken text)
    private func send(_ text: String) {
        guard !text.isEmpty, !waiting else { return }
        messages.append(ChatMessage(fromUser: true, text: text))
        input = ""
        waitingText = "Coco is thinking…"
        waiting = true

        // the greeting is only on screen, the server doesn't need it, so send from the first user message on
        let history = messages.drop(while: { !$0.fromUser }).filter { !$0.isError }

        Task {
            do {
                let reply = try await ChatService.send(history)
                messages.append(ChatMessage(fromUser: false, text: reply))
                if voiceOn { say(reply) }  // text shows first, voice follows
            } catch {
                print("Chat error:", error)  // details for us in Xcode's console
                messages.append(ChatMessage(fromUser: false,
                    text: "Sorry, I can't reach my brain right now. Please try again in a moment.",
                    isError: true))
            }
            waiting = false
        }
    }

    // mic button: 1st tap starts listening, 2nd tap stops -> text -> send to Coco
    private func micTapped() {
        if !recording {
            Task {
                guard await recorder.askPermission() else {
                    messages.append(ChatMessage(fromUser: false,
                        text: "I need the microphone to hear you. You can allow it in Settings → Coco.",
                        isError: true))
                    return
                }
                do {
                    voice.stop()        // don't record Coco's own voice
                    try recorder.start()
                    recording = true
                } catch {
                    print("Record error:", error)
                }
            }
        } else {
            recording = false
            let length = recorder.stop()
            guard length > 0.5 else { return }  // too short = probably a mis-tap, ignore

            waitingText = "Coco is listening…"
            waiting = true
            Task {
                do {
                    let text = try await ChatService.transcribe(recorder.fileURL)
                    waiting = false
                    if text.isEmpty {
                        messages.append(ChatMessage(fromUser: false,
                            text: "Sorry, I didn't catch that. Could you say it again?", isError: true))
                    } else {
                        send(text)  // your words appear as your bubble, Coco answers as usual
                    }
                } catch {
                    print("Transcribe error:", error)
                    waiting = false
                    messages.append(ChatMessage(fromUser: false,
                        text: "Sorry, I couldn't hear that properly. Please try again or type it.",
                        isError: true))
                }
            }
        }
    }

    // get Coco's voice from the server and play it. If it fails: no sound, text is still there.
    private func say(_ text: String) {
        Task {
            do {
                let mp3 = try await ChatService.speak(text)
                if voiceOn { voice.play(mp3) }  // check again: maybe turned off while loading
            } catch {
                print("Speak error:", error)
            }
        }
    }
}

// a single speech bubble: user on the right, Coco on the left
struct Bubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.fromUser { Spacer(minLength: 40) }

            Text(message.text)
                .font(.title3)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .foregroundStyle(message.fromUser ? .white : .primary)
                .background(message.fromUser ? Color.accentColor : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            if !message.fromUser { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    ContentView()
}
