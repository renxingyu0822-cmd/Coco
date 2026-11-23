//
//  SettingsView.swift
//  Coco
//
//  The ⚙️ screen (top right on the chat screen).
//  About you (name, she/he/they, town), which server Coco talks to (online / my Mac),
//  and the voice fingerprint (VoiceprintView). All saved on the phone.
//

import SwiftUI

struct SettingsView: View {
    // saved on the phone, same key ChatService reads
    @AppStorage(ChatService.serverKey) private var server = ChatService.defaultServer
    @AppStorage(ChatService.userNameKey) private var userName = ""
    @AppStorage(ChatService.userPronounsKey) private var userPronouns = ""
    @AppStorage(ChatService.userTownKey) private var userTown = ""
    @Environment(\.dismiss) private var dismiss

    enum Status { case checking, ok, unreachable }
    @State private var status = Status.checking

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Your name") {
                        TextField("e.g. Margaret, Oma", text: $userName)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    Picker("When Coco talks about you", selection: $userPronouns) {
                        Text("Just my name").tag("")
                        Text("she / her").tag("she/her")
                        Text("he / him").tag("he/him")
                        Text("they / them").tag("they/them")
                    }
                    LabeledContent("Your town") {
                        TextField("e.g. Hannover, Beijing", text: $userTown)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("About you")
                } footer: {
                    Text("Coco uses your name now and then. \"When Coco talks about you\" is how she refers to you to other people, like a visitor. Your town is for the weather when you don't say where.")
                }

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

                Section("Voice") {
                    NavigationLink {
                        VoiceprintView()
                    } label: {
                        Label("Voice fingerprint", systemImage: "waveform.badge.person.crop")
                    }
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
