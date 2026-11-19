//
//  SettingsView.swift
//  Coco
//
//  The ⚙️ screen (top right on the chat screen).
//  For now: which server Coco talks to (online / my Mac).
//  Next: voice fingerprint.
//

import SwiftUI

struct SettingsView: View {
    // saved on the phone, same key ChatService reads
    @AppStorage(ChatService.serverKey) private var server = ChatService.defaultServer
    @Environment(\.dismiss) private var dismiss

    enum Status { case checking, ok, unreachable }
    @State private var status = Status.checking

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Server", selection: $server) {
                        Text("Online").tag("online")
                        Text("My Mac").tag("mac")
                    }
                    .pickerStyle(.segmented)

                    statusLine
                } header: {
                    Text("Server")
                } footer: {
                    Text(server == "online"
                         ? "Works anywhere, Wi-Fi or mobile data."
                         : "Mac must be on the same Wi-Fi and the server running (type coco in the Mac's terminal).")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // check the server when the screen opens and after every switch
            .task(id: server) {
                status = .checking
                let ok = await ChatService.isReachable(ChatService.baseURL)
                status = ok ? .ok : .unreachable
            }
        }
    }

    @ViewBuilder private var statusLine: some View {
        switch status {
        case .checking:
            Label("Checking…", systemImage: "hourglass").foregroundStyle(.secondary)
        case .ok:
            Label("Connected", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
        case .unreachable:
            Label("Can't reach it", systemImage: "xmark.circle.fill").foregroundStyle(.red)
        }
    }
}

#Preview {
    SettingsView()
}
