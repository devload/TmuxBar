import SwiftUI

struct TemplatePickerView: View {
    @StateObject private var templateManager = TemplateManager.shared
    @State private var selectedTemplate: SessionTemplate?
    @State private var sessionName = ""
    @State private var workingDirectory = ""
    @State private var showDirectoryPicker = false
    @State private var errorMessage: String?

    let onDismiss: () -> Void
    let onCreateSession: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("New Session from Template")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Template Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                    ForEach(templateManager.allTemplates) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id
                        )
                        .onTapGesture {
                            selectedTemplate = template
                            if sessionName.isEmpty {
                                sessionName = generateSessionName(from: template.name)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 250)

            Divider()

            // Session Configuration
            if selectedTemplate != nil {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Session Name:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("my-session", text: $sessionName)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Working Directory:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            TextField("~/projects", text: $workingDirectory)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse") {
                                showDirectoryPicker = true
                            }
                        }
                    }
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Actions
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create Session") {
                    createSession()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedTemplate == nil || sessionName.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400, height: 500)
        .fileImporter(
            isPresented: $showDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                workingDirectory = url.path
            }
        }
    }

    private func generateSessionName(from templateName: String) -> String {
        let base = templateName.lowercased().replacingOccurrences(of: " ", with: "-")
        let timestamp = Int(Date().timeIntervalSince1970) % 10000
        return "\(base)-\(timestamp)"
    }

    private func createSession() {
        guard let template = selectedTemplate else { return }

        let name = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            errorMessage = "Session name cannot be empty"
            return
        }

        // Check if session exists
        if SessionManager.shared.sessions.contains(where: { $0.name == name }) {
            errorMessage = "Session '\(name)' already exists"
            return
        }

        // Create template with optional custom directory
        var customTemplate = template
        if !workingDirectory.isEmpty {
            customTemplate.workingDirectory = workingDirectory
        }

        let success = TmuxService.shared.createSessionFromTemplate(customTemplate, name: name)
        if success {
            SessionManager.shared.refreshSessions()
            onCreateSession(name)
            onDismiss()
        } else {
            errorMessage = "Failed to create session"
        }
    }
}

struct TemplateCard: View {
    let template: SessionTemplate
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: template.icon)
                .font(.title)
                .foregroundColor(isSelected ? .white : .accentColor)

            Text(template.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)

            Text(template.description)
                .font(.caption2)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // Window preview
            HStack(spacing: 4) {
                ForEach(template.windows.prefix(3)) { window in
                    Image(systemName: window.layout.icon)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                }
                if template.windows.count > 3 {
                    Text("+\(template.windows.count - 3)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}
