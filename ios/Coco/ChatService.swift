//
//  ChatService.swift
//  Coco
//
//  Talks to our Python server: sends the conversation, gets Coco's reply.
//  Same thing server/chat_cli.py does, just in Swift.
//
//  Every request carries the app password (header X-Coco-Key), so the online
//  server knows it's our app (see server/app/auth.py). The password lives in
//  Secrets.swift, which is git-ignored (public repo!). New checkout? Create
//  ios/Coco/Secrets.swift with:
//      enum Secrets { static let appPassword = "<same as COCO_APP_PASSWORD on the server>" }
//

import Foundation

enum ChatService {
    // the Mac's network name (doesn't change like an IP does). Works from the iPhone on the same Wi-Fi/hotspot,
    // and in Xcode Preview. Check it on the Mac with: scutil --get LocalHostName
    static let baseURL = URL(string: "http://dafeideMacBook-Pro.local:8000")!

    // a POST request to one of the server's addresses, with the app password attached
    private static func post(_ path: String) -> URLRequest {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue(Secrets.appPassword, forHTTPHeaderField: "X-Coco-Key")
        req.timeoutInterval = 30
        return req
    }

    // what the server expects / sends back (same shapes as in main.py)
    private struct Message: Codable { let role: String; let content: String }
    private struct Request: Codable { let messages: [Message] }
    private struct Reply: Codable { let reply: String }

    static func send(_ history: [ChatMessage]) async throws -> String {
        var req = post("chat")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

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

    // text in -> Coco's voice out (mp3 data), via the server's /speak
    private struct SpeakRequest: Codable { let text: String }

    static func speak(_ text: String) async throws -> Data {
        var req = post("speak")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(SpeakRequest(text: text))

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    // your recording in -> text out, via the server's /transcribe
    private struct TranscribeReply: Codable { let text: String }

    static func transcribe(_ fileURL: URL) async throws -> String {
        var req = post("transcribe")

        // upload as a "form with a file" (multipart), like a file upload on a website.
        // the boundary is just a unique separator line between the parts.
        let boundary = "coco-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(try Data(contentsOf: fileURL))
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TranscribeReply.self, from: data).text
    }
}
