import SwiftUI

struct MenuBarView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var preferencesManager = PreferencesManager.shared

    @State private var showingNewSession = false
    @State private var showingPreferences = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "terminal.fill")
                Text("TmuxBar")
                    .font(.headline)
                Spacer()

                if sessionManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Button(action: { sessionManager.refreshSessions() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Session List
            if sessionManager.sessions.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Favorites
                        if !sessionManager.favoriteSessions.isEmpty {
                            sectionHeader("Favorites")
                            ForEach(sessionManager.favoriteSessions) { session in
                                sessionRow(session, isFavorite: true)
                            }
                        }

                        // Groups
                        ForEach(Array(sessionManager.groupedSessions.keys).sorted(), id: \.self) { groupName in
                            sectionHeader(groupName)
                            ForEach(sessionManager.groupedSessions[groupName] ?? []) { session in
                                sessionRow(session, isFavorite: sessionManager.isFavorite(session))
                            }
                        }

                        // Other Sessions
                        let others = sessionManager.ungroupedSessions.filter { !sessionManager.isFavorite($0) }
                        if !others.isEmpty {
                            sectionHeader("Sessions")
                            ForEach(others) { session in
                                sessionRow(session, isFavorite: false)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            }

            Divider()

            // Actions
            VStack(spacing: 4) {
                actionButton("New Session...", systemImage: "plus.circle") {
                    showingNewSession = true
                }

                actionButton("Preferences...", systemImage: "gear") {
                    showingPreferences = true
                }

                Divider()

                actionButton("Quit TmuxBar", systemImage: "xmark.circle") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 280)
        .sheet(isPresented: $showingNewSession) {
            NewSessionView { showingNewSession = false }
        }
        .sheet(isPresented: $showingPreferences) {
            PreferencesView()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.title)
                .foregroundColor(.secondary)
            Text("No tmux sessions")
                .font(.subheadline)
            Text("Create a new session to get started")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func sessionRow(_ session: TmuxSession, isFavorite: Bool) -> some View {
        Button(action: {
            sessionManager.attachSession(session)
        }) {
            HStack(spacing: 8) {
                if isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(session.name)
                            .fontWeight(.medium)

                        if session.isAttached {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                        }
                    }

                    if preferencesManager.showWindowCount {
                        Text("\(session.windowCount) window\(session.windowCount == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Attach") {
                sessionManager.attachSession(session)
            }
            .disabled(session.isAttached)

            Divider()

            Button("New Window") {
                sessionManager.createWindow(in: session)
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

    private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
