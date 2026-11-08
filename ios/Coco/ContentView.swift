//
//  ContentView.swift
//  Coco
//
//  Chat screen. Two ways to talk to Coco:
//    1. type + send button
//    2. tap the mic = hands-free conversation: you talk, Coco notices when you stop,
//       answers out loud, then listens again by herself. Until you tap "End".
//

import SwiftUI

// one chat bubble
struct ChatMessage: Identifiable {
    let id = UUID()
    let fromUser: Bool
    let text: String
    var isError = false  // error notes are shown, but never sent to the server
}

// what the hands-free conversation is doing right now
enum Phase { case idle, listening, thinking, speaking }

struct ContentView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(fromUser: false, text: "Hello! I'm Coco. How are you today?")
    ]
    @State private var input = ""
    @State private var waiting = false  // true while Coco is "thinking" (shows the grey bubble)
    @State private var voiceOn = true   // read Coco's replies aloud?
    @State private var voice = VoicePlayer()
    @State private var recorder = VoiceRecorder()
    @State private var inConversation = false  // hands-free mode on?
    @State private var phase = Phase.idle

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

            if inConversation {
                conversationPanel   // big status + End button
            } else {
                inputRow            // mic + text field + send
            }
        }
    }

    // ── bottom area, normal mode: big mic button + text field + big send button ──
    private var inputRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Button(action: startConversation) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 44))
            }
            .disabled(waiting)
            .accessibilityLabel("Talk to Coco")

            TextField("Type a message…", text: $input, axis: .vertical)
                .font(.title3)
                .lineLimit(1...4)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button(action: sendTyped) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 44))
            }
            .disabled(trimmed.isEmpty || waiting)  // no double sends
            .accessibilityLabel("Send")
        }
        .padding()
    }

    // ── bottom area, hands-free mode: what's happening + a big End button ──
    private var conversationPanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: phaseIcon)
                    .font(.system(size: 34))
                    .symbolEffect(.pulse, isActive: phase == .listening)  // gentle pulse = "I'm listening"
                Text(phaseText)
                    .font(.title2.bold())
            }
            .foregroundStyle(phase == .listening ? .green : .primary)

            Button(action: endConversation) {
                Text("End conversation")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
    }

    private var phaseText: String {
        switch phase {
        case .listening: "Listening… just talk"
        case .thinking: "Coco is thinking…"
        case .speaking: "Coco is speaking…"
        case .idle: ""
        }
    }

    private var phaseIcon: String {
        switch phase {
        case .listening: "mic.fill"
        case .thinking: "ellipsis.bubble.fill"
        case .speaking: "speaker.wave.2.fill"
        case .idle: "mic"
        }
    }

    private var trimmed: String { input.trimmingCharacters(in: .whitespacesAndNewlines) }

    // ── typed message ──
    private func sendTyped() {
        let text = trimmed
        input = ""
        Task {
            if let reply = await ask(text), voiceOn {
                if let mp3 = try? await ChatService.speak(reply) { await voice.play(mp3) }
            }
        }
    }

    // ask Coco: adds your bubble, waits for her reply, adds her bubble. nil = something failed.
    private func ask(_ text: String) async -> String? {
        guard !text.isEmpty, !waiting else { return nil }
        messages.append(ChatMessage(fromUser: true, text: text))
        waiting = true
        defer { waiting = false }

        // the greeting is only on screen, the server doesn't need it, so send from the first user message on
        let history = messages.drop(while: { !$0.fromUser }).filter { !$0.isError }
        do {
            let reply = try await ChatService.send(history)
            messages.append(ChatMessage(fromUser: false, text: reply))
            return reply
        } catch {
            print("Chat error:", error)  // details for us in Xcode's console
            messages.append(ChatMessage(fromUser: false,
                text: "Sorry, I can't reach my brain right now. Please try again in a moment.",
                isError: true))
            return nil
        }
    }

    // ── hands-free conversation: listen -> think -> speak -> listen again ... ──
    private func startConversation() {
        Task {
            guard await recorder.askPermission() else {
                messages.append(ChatMessage(fromUser: false,
                    text: "I need the microphone to hear you. You can allow it in Settings → Coco.",
                    isError: true))
                return
            }
            inConversation = true

            while inConversation {
                // 1. listen until you stop talking
                phase = .listening
                let heard: VoiceRecorder.Result
                do { heard = try await recorder.listen() } catch {
                    print("Record error:", error); break
                }
                if heard == .cancelled || !inConversation { break }
                if heard == .silent {
                    // nobody talked for a while: stop, so the mic isn't on forever
                    messages.append(ChatMessage(fromUser: false,
                        text: "I'll be right here. Tap the microphone whenever you want to talk.",
                        isError: true))
                    break
                }

                // 2. your voice -> text
                phase = .thinking
                let text: String
                do { text = try await ChatService.transcribe(recorder.fileURL) } catch {
                    print("Transcribe error:", error)
                    messages.append(ChatMessage(fromUser: false,
                        text: "Sorry, I couldn't hear that properly. Please try again.", isError: true))
                    break
                }
                if text.isEmpty { continue }  // nothing understood: just listen again

                // 3. ask Coco
                guard let reply = await ask(text), inConversation else { break }

                // 4. Coco speaks; the mic stays off until she's done (so she doesn't hear herself)
                if voiceOn {
                    phase = .speaking
                    if let mp3 = try? await ChatService.speak(reply), inConversation {
                        await voice.play(mp3)
                    }
                }
            }

            // conversation over
            inConversation = false
            phase = .idle
        }
    }

    private func endConversation() {
        inConversation = false
        recorder.cancel()   // stop listening
        voice.stop()        // stop her mid-sentence
        phase = .idle
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
