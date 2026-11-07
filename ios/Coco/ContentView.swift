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
    @State private var waiting = false  // true while Coco is "thinking"
    @State private var voiceOn = true   // read Coco's replies aloud?
    @State private var voice = VoicePlayer()

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
                            Bubble(message: ChatMessage(fromUser: false, text: "Coco is thinking…"))
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

            // input row: big text field + big send button
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Type a message…", text: $input, axis: .vertical)
                    .font(.title3)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 44))
                }
                .disabled(trimmed.isEmpty || waiting)  // no double sends
                .accessibilityLabel("Send")
            }
            .padding()
        }
    }

    private var trimmed: String { input.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func send() {
        guard !trimmed.isEmpty, !waiting else { return }
        messages.append(ChatMessage(fromUser: true, text: trimmed))
        input = ""
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
