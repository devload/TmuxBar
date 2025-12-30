import SwiftUI

struct SessionPreviewView: View {
    let session: TmuxSession

    @State private var previewContent: String = ""
    @State private var currentCommand: String = ""
    @State private var currentPath: String = ""
    @State private var isLoading = true

    private let tmuxService = TmuxService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.green)
                Text(session.name)
                    .font(.headline)
                Spacer()
                if session.isAttached {
                    Text("Attached")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }

            Divider()

            // Info
            HStack(spacing: 16) {
                Label(currentPath.isEmpty ? "~" : shortenPath(currentPath), systemImage: "folder")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !currentCommand.isEmpty {
                    Label(currentCommand, systemImage: "play.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            // Preview Terminal
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .frame(height: 200)
            } else {
                ScrollView {
                    Text(previewContent.isEmpty ? "No output" : previewContent)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(height: 200)
                .background(Color.black.opacity(0.9))
                .cornerRadius(8)
            }

            // Windows info
            if !session.windows.isEmpty {
                Divider()
                Text("Windows (\(session.windows.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(session.windows) { window in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(window.isActive ? Color.green : Color.gray)
                                    .frame(width: 6, height: 6)
                                Text(window.name)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 350)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 10)
        .onAppear {
            loadPreview()
        }
    }

    private func loadPreview() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            let content = tmuxService.capturePane(sessionName: session.name)
            let command = tmuxService.getCurrentCommand(sessionName: session.name)
            let path = tmuxService.getCurrentPath(sessionName: session.name)

            DispatchQueue.main.async {
                self.previewContent = content
                self.currentCommand = command
                self.currentPath = path
                self.isLoading = false
            }
        }
    }

    private func shortenPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

// MARK: - Preview Popover Modifier

struct SessionPreviewPopover: ViewModifier {
    let session: TmuxSession
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .popover(isPresented: $isPresented, arrowEdge: .trailing) {
                SessionPreviewView(session: session)
            }
    }
}

extension View {
    func sessionPreview(_ session: TmuxSession, isPresented: Binding<Bool>) -> some View {
        modifier(SessionPreviewPopover(session: session, isPresented: isPresented))
    }
}
