import SwiftUI

struct SessionDetailView: View {
    let session: TmuxSession

    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedWindow: TmuxWindow?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Session Header
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(session.name)
                            .font(.headline)

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

                    Text("\(session.windowCount) window\(session.windowCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Attach") {
                    sessionManager.attachSession(session)
                }
                .disabled(session.isAttached)
            }

            Divider()

            // Windows List
            Text("Windows")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if session.windows.isEmpty {
                Text("Loading windows...")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                List(selection: $selectedWindow) {
                    ForEach(session.windows) { window in
                        WindowRowView(window: window, session: session)
                            .tag(window)
                    }
                }
                .listStyle(.inset)
            }

            // Actions
            HStack {
                Button(action: {
                    sessionManager.createWindow(in: session)
                }) {
                    Label("New Window", systemImage: "plus.rectangle")
                }

                Button(action: {
                    sessionManager.splitHorizontal(in: session)
                }) {
                    Label("Split H", systemImage: "rectangle.split.1x2")
                }

                Button(action: {
                    sessionManager.splitVertical(in: session)
                }) {
                    Label("Split V", systemImage: "rectangle.split.2x1")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .frame(minWidth: 300, minHeight: 300)
    }
}

struct WindowRowView: View {
    let window: TmuxWindow
    let session: TmuxSession

    var body: some View {
        HStack {
            Image(systemName: window.isActive ? "rectangle.fill" : "rectangle")
                .foregroundColor(window.isActive ? .accentColor : .secondary)

            VStack(alignment: .leading) {
                Text(window.name)
                    .fontWeight(window.isActive ? .medium : .regular)

                Text("\(window.paneCount) pane\(window.paneCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if window.isActive {
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 2)
    }
}
