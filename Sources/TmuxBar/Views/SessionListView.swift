import SwiftUI

struct SessionListView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var preferencesManager = PreferencesManager.shared

    var body: some View {
        VStack(spacing: 0) {
            if sessionManager.isLoading && sessionManager.sessions.isEmpty {
                ProgressView()
                    .padding()
            } else if sessionManager.sessions.isEmpty {
                emptyStateView
            } else {
                sessionList
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No tmux sessions")
                .font(.headline)
            Text("Create a new session to get started")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var sessionList: some View {
        List {
            // Favorites Section
            if !sessionManager.favoriteSessions.isEmpty {
                Section("Favorites") {
                    ForEach(sessionManager.favoriteSessions) { session in
                        SessionRowView(session: session, isFavorite: true)
                    }
                }
            }

            // Grouped Sessions
            ForEach(Array(sessionManager.groupedSessions.keys).sorted(), id: \.self) { groupName in
                Section(groupName) {
                    ForEach(sessionManager.groupedSessions[groupName] ?? []) { session in
                        SessionRowView(session: session, isFavorite: sessionManager.isFavorite(session))
                    }
                }
            }

            // Ungrouped Sessions
            let ungrouped = sessionManager.ungroupedSessions.filter { !sessionManager.isFavorite($0) }
            if !ungrouped.isEmpty {
                Section("Other Sessions") {
                    ForEach(ungrouped) { session in
                        SessionRowView(session: session, isFavorite: false)
                    }
                }
            }
        }
    }
}

struct SessionRowView: View {
    let session: TmuxSession
    let isFavorite: Bool

    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var preferencesManager = PreferencesManager.shared

    var body: some View {
        HStack {
            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(session.name)
                        .fontWeight(.medium)

                    if session.isAttached {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }

                if preferencesManager.showWindowCount {
                    Text("\(session.windowCount) window\(session.windowCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: {
                sessionManager.attachSession(session)
            }) {
                Text("Attach")
                    .font(.caption)
            }
            .disabled(session.isAttached)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Attach") {
                sessionManager.attachSession(session)
            }
            .disabled(session.isAttached)

            Divider()

            Button("New Window") {
                sessionManager.createWindow(in: session)
            }

            Menu("Split Pane") {
                Button("Horizontal") {
                    sessionManager.splitHorizontal(in: session)
                }
                Button("Vertical") {
                    sessionManager.splitVertical(in: session)
                }
            }

            Divider()

            Button(isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                sessionManager.toggleFavorite(session)
            }

            Divider()

            Button("Kill Session", role: .destructive) {
                sessionManager.killSession(session)
            }
        }
    }
}
