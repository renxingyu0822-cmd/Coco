//
//  ContentView.swift
//  Coco
//
//  Chat screen. Step 1: looks only, Coco gives a fake reply (no server yet).
//

import SwiftUI

// one chat bubble
struct ChatMessage: Identifiable {
    let id = UUID()
    let fromUser: Bool
    let text: String
}

struct ContentView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(fromUser: false, text: "Hello! I'm Coco. How are you today?")
    ]
    @State private var input = ""

    var body: some View {
        VStack(spacing: 0) {
            // header
            Text("Coco")
                .font(.title.bold())
                .padding(.vertical, 12)

            Divider()

            // the conversation, jumps to the newest message
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(messages) { msg in
                            Bubble(message: msg).id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
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
                .disabled(trimmed.isEmpty)
                .accessibilityLabel("Send")
            }
            .padding()
        }
    }

    private var trimmed: String { input.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func send() {
        guard !trimmed.isEmpty else { return }
        messages.append(ChatMessage(fromUser: true, text: trimmed))
        input = ""
        // fake reply for now, the real one comes from the server in step 2
        messages.append(ChatMessage(fromUser: false, text: "(Coco will answer here soon)"))
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
