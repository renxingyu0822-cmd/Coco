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
    // ── which server the app talks to: picked in Settings (⚙️), the phone remembers it ──
    //   "online" = online server (Hetzner, Helsinki). Works anywhere, Wi-Fi or mobile data, Mac can be off.
    //   "mac"    = the Mac (playground/backup). Only on the same Wi-Fi/hotspot, and the Mac's server must run (`coco`).
    static let serverKey = "server"        // name of the saved setting (SettingsView uses the same)
    static let defaultServer = "mac"       // first launch: the Mac, for the voiceprint tests (Nov 19)

    static let onlineURL = URL(string: "https://65-108-248-13.sslip.io")!
    // the Mac's network name (doesn't change like an IP does). Check it with: scutil --get LocalHostName
    static let macURL = URL(string: "http://dafeideMacBook-Pro.local:8000")!

    // read fresh every time, so a switch in Settings counts right away
    static var baseURL: URL {
        let choice = UserDefaults.standard.string(forKey: serverKey) ?? defaultServer
        return choice == "online" ? onlineURL : macURL
    }

    // "are you there?" -> true if the server answers /health within a few seconds
    static func isReachable(_ url: URL) async -> Bool {
        var req = URLRequest(url: url.appendingPathComponent("health"))
        req.timeoutInterval = 5
        guard let (_, resp) = try? await URLSession.shared.data(for: req) else { return false }
        return (resp as? HTTPURLResponse)?.statusCode == 200
    }

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

    // upload files as a "form with files" (multipart), like a file upload on a website.
    // the boundary is just a unique separator line between the parts.
    private static func attach(_ files: [URL], field: String, type: String, to req: inout URLRequest) throws {
        let boundary = "coco-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        for file in files {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(field)\"; filename=\"\(file.lastPathComponent)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(type)\r\n\r\n".data(using: .utf8)!)
            body.append(try Data(contentsOf: file))
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body
    }

    // your recording in -> text out, via the server's /transcribe
    private struct TranscribeReply: Codable { let text: String }

    static func transcribe(_ fileURL: URL) async throws -> String {
        var req = post("transcribe")
        try attach([fileURL], field: "audio", type: "audio/m4a", to: &req)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TranscribeReply.self, from: data).text
    }

    // ── voiceprint (server/app/voiceprint.py) ──

    // the server's error text ("Recording too short…"), so we can show it as is
    struct ServerError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }
    private struct Detail: Codable { let detail: String }

    // send a request, throw the server's own message if it says no
    private static func run(_ req: URLRequest) async throws -> Data {
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else {
            let msg = (try? JSONDecoder().decode(Detail.self, from: data))?.detail
            throw ServerError(message: msg ?? "Server error (\(code)).")
        }
        return data
    }

    private struct Enrolled: Codable { let enrolled: Bool }
    struct VoiceCheck: Codable { let score: Double; let is_you: Bool; let threshold: Double }

    // is a fingerprint saved?
    static func voiceprintEnrolled() async throws -> Bool {
        var req = post("voiceprint")
        req.httpMethod = "GET"
        return try JSONDecoder().decode(Enrolled.self, from: try await run(req)).enrolled
    }

    // a few wav clips of the user -> server saves the fingerprint
    static func enrollVoiceprint(_ clips: [URL]) async throws {
        var req = post("voiceprint/enroll")
        req.timeoutInterval = 90    // first use loads the model on the server (~30 s on the Mac)
        try attach(clips, field: "clips", type: "audio/wav", to: &req)
        _ = try await run(req)
    }

    // one wav clip -> is it the user? + score
    static func checkVoiceprint(_ clip: URL) async throws -> VoiceCheck {
        var req = post("voiceprint/check")
        req.timeoutInterval = 90
        try attach([clip], field: "clip", type: "audio/wav", to: &req)
        return try JSONDecoder().decode(VoiceCheck.self, from: try await run(req))
    }

    // forget the fingerprint
    static func deleteVoiceprint() async throws {
        var req = post("voiceprint")
        req.httpMethod = "DELETE"
        _ = try await run(req)
    }
}
