//
//  ContentView.swift
//  Coco
//
//  Chat screen, layout from the hand-drawn sketches:
//
//  Text mode                         Voice mode
//  ┌──────────────────────┐          ┌──────────────────────┐
//  │ Coco             🔊  │          │ (✕) Stop voice chat  │
//  │ [C][panda] Tap Coco  │          │  bubbles …           │
//  │  bubbles …           │          │     [ panda ]        │
//  │ [Type a message…] ↑  │          │  Listening… just talk│
//  └──────────────────────┘          └──────────────────────┘
//
//  Voice mode = hands-free: you talk, Coco notices when you stop, answers out
//  loud, then listens again by herself. Until you tap "Stop voice chat".
//
//  Panda pictures live in Assets: panda-idle ("Call Coco"), panda-listening, panda-thinking
//  (drawn by hand, handwritten words removed; thinking + speaking share one picture for now).
//  Colour: "AccentColor" in Assets = black (light mode) / white (dark mode).
//  Things drawn ON the accent colour use Color(.systemBackground), the opposite,
//  so they stay readable in both modes.
//

import SwiftUI

// one chat bubble
struct ChatMessage: Identifiable {
    let id = UUID()
    let fromUser: Bool
    let text: String
    var isError = false  // error notes are shown, but never sent to the server
}

// what the voice chat is doing right now
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
    @State private var inConversation = false  // voice mode on?
    @State private var phase = Phase.idle

    var body: some View {
        VStack(spacing: 0) {
            if inConversation {
                stopBar             // (✕) Stop voice chat
            } else {
                header              // Coco + speaker button
                Divider()
                startVoiceCard      // big panda button
            }

            Divider()
            chatList                // the bubbles (both modes)
            Divider()

            if inConversation {
                pandaPanel          // big panda + "Listening…"
            } else {
                inputRow            // text field + send
            }
        }
        .animation(.easeInOut(duration: 0.3), value: inConversation)  // smooth switch between modes
    }

    // ── text mode: header ──
    private var header: some View {
        HStack {
            Text("Coco")
                .font(.largeTitle.bold())
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
        .padding(.vertical, 6)
    }

    // ── text mode: the giant "start voice chat" button (easy to find) ──
    private var startVoiceCard: some View {
        Button(action: startConversation) {
            HStack(spacing: 14) {
                // the round "C" logo
                Text("C")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(Color.accentColor))

                Image("panda-idle")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 90)
                    .blendMode(.multiply)   // makes the white paper of the sketch disappear on the card

                Spacer(minLength: 0)
            }
            .overlay(alignment: .bottom) {
                Text("Tap Coco to start voice chat")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .offset(y: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.accentColor.opacity(0.08)))
        }
        .buttonStyle(.plain)
        .disabled(waiting)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .accessibilityLabel("Tap Coco to start voice chat")
    }

    // ── voice mode: big stop button at the top ──
    private var stopBar: some View {
        Button(action: endConversation) {
            HStack(spacing: 14) {
                Image(systemName: "xmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.red))
                Text("Stop voice chat")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop voice chat")
    }

    // ── the bubbles, jumps to the newest message ──
    private var chatList: some View {
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
    }

    // ── voice mode: the big panda + what's happening ──
    private var pandaPanel: some View {
        VStack(spacing: 10) {
            PandaStage(phase: phase)
                .frame(height: 200)

            Text(phaseText)
                .font(.title2.bold())
                .foregroundStyle(phase == .listening ? .green : .primary)
                .contentTransition(.opacity)
                .animation(.easeInOut, value: phase)
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

    // ── text mode: text field + round send button ──
    private var inputRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
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

    // ── voice chat: listen -> think -> speak -> listen again ... ──
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
                        text: "I'll be right here. Tap me whenever you want to talk.",
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

            // voice chat over
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

// ── the big panda in voice mode, in a soft hexagon (like the sketch) ──
//   listening:          "panda-listening", gently pulsing (= I'm all ears)
//   thinking, speaking: "panda-thinking", thinking sways slowly, speaking bobs a little
struct PandaStage: View {
    let phase: Phase

    var body: some View {
        // TimelineView redraws ~60x per second; we use the time `t` for the small movements
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let picture = phase == .listening ? "panda-listening" : "panda-thinking"

            let scale = phase == .listening ? 1 + 0.03 * sin(t * 4) : 1       // pulse
            let bob = phase == .speaking ? -4 * abs(sin(t * 6)) : 0            // little hops while talking
            let sway = phase == .thinking ? 3 * sin(t * 1.5) : 0               // slow tilt while thinking

            ZStack {
                Hexagon()
                    .fill(Color.accentColor.opacity(0.10))
                Hexagon()
                    .stroke(Color.accentColor.opacity(0.35),
                            style: StrokeStyle(lineWidth: 3, lineJoin: .round))  // round corners = softer

                Image(picture)
                    .resizable()
                    .scaledToFit()
                    .blendMode(.multiply)   // hides the white paper behind the sketch
                    .padding(28)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(sway))
                    .offset(y: bob)
            }
            .aspectRatio(1.1, contentMode: .fit)
            .frame(maxWidth: .infinity)
        }
    }
}

// a soft hexagon, flat on top and bottom
struct Hexagon: Shape {
    func path(in r: CGRect) -> Path {
        let inset = r.width * 0.22  // how far the top/bottom edges are pulled in
        var p = Path()
        p.move(to: CGPoint(x: r.minX + inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX - inset, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + inset, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

// ── a solid round button with a white symbol (send) ──
// accent (black/white) when it can be pressed, light grey when not
struct RoundButton: View {
    let systemName: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(.systemBackground))
                .frame(width: 50, height: 50)
                .background(Circle().fill(enabled ? Color.accentColor : Color(.systemGray4)))
        }
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)
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
                .foregroundStyle(message.fromUser ? Color(.systemBackground) : .primary)
                .background(message.fromUser ? Color.accentColor : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            if !message.fromUser { Spacer(minLength: 40) }
        }
    }
}

#Preview("Chat") {
    ContentView()
}

// the panda in each voice-mode state, to see the movements in Xcode without talking
#Preview("Panda") {
    VStack(spacing: 20) {
        PandaStage(phase: .listening).frame(height: 180)
        PandaStage(phase: .thinking).frame(height: 180)
        PandaStage(phase: .speaking).frame(height: 180)
    }
    .padding()
}
