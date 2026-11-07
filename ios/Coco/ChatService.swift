//
//  ChatService.swift
//  Coco
//
//  Talks to our Python server: sends the conversation, gets Coco's reply.
//  Same thing server/chat_cli.py does, just in Swift.
//

import Foundation

enum ChatService {
    // the Mac's network name (doesn't change like an IP does). Works from the iPhone on the same Wi-Fi/hotspot,
    // and in Xcode Preview. Check it on the Mac with: scutil --get LocalHostName
    static let baseURL = URL(string: "http://dafeideMacBook-Pro.local:8000")!

    // what the server expects / sends back (same shapes as in main.py)
    private struct Message: Codable { let role: String; let content: String }
    private struct Request: Codable { let messages: [Message] }
    private struct Reply: Codable { let reply: String }

    static func send(_ history: [ChatMessage]) async throws -> String {
        var req = URLRequest(url: baseURL.appendingPathComponent("chat"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30

        let body = Request(messages: history.map {
            Message(role: $0.fromUser ? "user" : "assistant", content: $0.text)
        })
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Reply.self, from: data).reply
    }
}
