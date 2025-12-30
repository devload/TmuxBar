import SwiftUI

struct NewSessionView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var sessionName = ""
    @State private var workingDirectory = ""
    @State private var showDirectoryPicker = false
    @State private var errorMessage: String?

    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Create New Session")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Session Name:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("my-session", text: $sessionName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Working Directory (optional):")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("~/", text: $workingDirectory)
                        .textFieldStyle(.roundedBorder)

                    Button("Browse...") {
                        showDirectoryPicker = true
                    }
                }
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    createSession()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 350)
        .fileImporter(
            isPresented: $showDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    workingDirectory = url.path
                }
            case .failure(let error):
                print("Directory picker error: \(error)")
            }
        }
    }

    private func createSession() {
        let name = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            errorMessage = "Session name cannot be empty"
            return
        }

        // Check if session already exists
        if sessionManager.sessions.contains(where: { $0.name == name }) {
            errorMessage = "Session '\(name)' already exists"
            return
        }

        let directory = workingDirectory.isEmpty ? nil : workingDirectory
        sessionManager.createSession(name: name, directory: directory)
        onDismiss()
    }
}
