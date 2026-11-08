//
//  ContentView.swift
//  Coco
//
//  Chat screen. Two ways to talk to Coco:
//    1. type + send button
//    2. tap the mic = hands-free conversation: you talk, Coco notices when you stop,
//       answers out loud, then listens again by herself. Until you tap "End".
//
//  Colour: "AccentColor" in Assets = Coco's warm coral. Change it there, everything follows.
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
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(voiceOn ? Color.accentColor : .secondary)
                            .frame(width: 48, height: 48)  // big enough to hit
                            .background(Circle().fill(Color(.secondarySystemBackground)))
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
                conversationPanel   // big orb + status + End button
            } else {
                inputRow            // mic + text field + send
            }
        }
        .animation(.easeInOut(duration: 0.25), value: inConversation)  // smooth switch between the two
    }

    // ── bottom area, normal mode: round mic button + text field + round send button ──
    private var inputRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            RoundButton(systemName: "mic.fill", enabled: !waiting, action: startConversation)
                .accessibilityLabel("Talk to Coco")

            TextField("Type a message…", text: $input, axis: .vertical)
                .font(.title3)
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color(.secondarySystemBackground)))

            RoundButton(systemName: "arrow.up", enabled: !trimmed.isEmpty && !waiting, action: sendTyped)
                .accessibilityLabel("Send")
        }
        .padding()
    }

    // ── bottom area, hands-free mode: the orb, what's happening, a big End button ──
    private var conversationPanel: some View {
        VStack(spacing: 16) {
            CocoOrb(phase: phase)
                .frame(height: 150)

            Text(phaseText)
                .font(.title2.bold())
                .foregroundStyle(phase == .listening ? .green : .primary)
                .contentTransition(.opacity)
                .animation(.easeInOut, value: phase)

            Button(action: endConversation) {
                Label("End conversation", systemImage: "xmark")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Capsule().fill(Color.red))
            }
        }
        .padding()
    }

    private var phaseText: String {
        switch phase {
        case .listening: "Listening… just talk"
        case .thinking: "Coco is thinking…"
        case .speaking: "Coco is speaking…"
        case .idle: " "
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

// ── a solid round button with a white symbol (mic, send) ──
// coral when it can be pressed, light grey when not
struct RoundButton: View {
    let systemName: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(enabled ? Color.accentColor : Color(.systemGray4)))
        }
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }
}

// ── the big animated circle in conversation mode, shows what Coco is doing ──
//   listening: green, soft rings pulsing outward
//   thinking:  coral, slowly "breathing"
//   speaking:  coral, little sound bars moving
struct CocoOrb: View {
    let phase: Phase

    var body: some View {
        // TimelineView redraws ~60x per second; we use the time `t` to animate
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let color: Color = phase == .listening ? .green : .accentColor

            ZStack {
                if phase == .listening {
                    // 3 rings growing and fading, one after another
                    ForEach(0..<3) { i in
                        let p = (t / 2 + Double(i) / 3).truncatingRemainder(dividingBy: 1)  // 0 -> 1
                        Circle()
                            .stroke(color.opacity(0.5 * (1 - p)), lineWidth: 3)
                            .frame(width: 90 + 60 * p, height: 90 + 60 * p)
                    }
                }

                // the main circle; "breathes" while thinking
                let breathe = phase == .thinking ? 1 + 0.06 * sin(t * 3) : 1
                Circle()
                    .fill(color.gradient)
                    .frame(width: 90, height: 90)
                    .scaleEffect(breathe)
                    .shadow(color: color.opacity(0.4), radius: 12)

                // what's inside the circle
                switch phase {
                case .listening:
                    Image(systemName: "mic.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                case .thinking:
                    // three dots lighting up one after another
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(.white.opacity(0.4 + 0.6 * max(0, sin(t * 4 - Double(i)))))
                                .frame(width: 10, height: 10)
                        }
                    }
                case .speaking:
                    // 5 sound bars going up and down
                    HStack(spacing: 5) {
                        ForEach(0..<5) { i in
                            Capsule()
                                .fill(.white)
                                .frame(width: 6, height: 12 + 22 * abs(sin(t * 5 + Double(i) * 0.9)))
                        }
                    }
                case .idle:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
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

#Preview("Chat") {
    ContentView()
}

// preview of the orb in each state, to see the animations in Xcode without talking
#Preview("Orb") {
    VStack(spacing: 30) {
        CocoOrb(phase: .listening).frame(height: 150)
        CocoOrb(phase: .thinking).frame(height: 150)
        CocoOrb(phase: .speaking).frame(height: 150)
    }
}
