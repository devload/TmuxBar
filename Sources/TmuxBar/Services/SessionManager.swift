import Foundation
import Combine

final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published private(set) var sessions: [TmuxSession] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?

    private let tmuxService = TmuxService.shared
    private let preferencesManager = PreferencesManager.shared
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Observe refresh interval changes
        preferencesManager.$refreshInterval
            .sink { [weak self] interval in
                self?.updateRefreshTimer(interval: interval)
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties

    var favoriteSessions: [TmuxSession] {
        let favoriteNames = preferencesManager.favorites
        return sessions.filter { favoriteNames.contains($0.name) }
            .sorted { $0.name < $1.name }
    }

    var ungroupedSessions: [TmuxSession] {
        let groupedNames = preferencesManager.groups.values.flatMap { $0 }
        return sessions.filter { !groupedNames.contains($0.name) }
            .sorted { $0.name < $1.name }
    }

    var groupedSessions: [String: [TmuxSession]] {
        var result: [String: [TmuxSession]] = [:]
        for (groupName, sessionNames) in preferencesManager.groups {
            let groupSessions = sessions.filter { sessionNames.contains($0.name) }
            if !groupSessions.isEmpty {
                result[groupName] = groupSessions.sorted { $0.name < $1.name }
            }
        }
        return result
    }

    // MARK: - Monitoring

    func startMonitoring() {
        refreshSessions()
        updateRefreshTimer(interval: preferencesManager.refreshInterval)
    }

    func stopMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func updateRefreshTimer(interval: TimeInterval) {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refreshSessions()
        }
    }

    // MARK: - Session Operations

    func refreshSessions() {
        isLoading = true
        lastError = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let sessions = self.tmuxService.listSessions()

            DispatchQueue.main.async {
                self.sessions = sessions
                self.isLoading = false
            }
        }
    }

    func createSession(name: String, directory: String? = nil) {
        let success = tmuxService.createSession(name: name, directory: directory)
        if success {
            refreshSessions()
        } else {
            lastError = "Failed to create session '\(name)'"
        }
    }

    func killSession(_ session: TmuxSession) {
        let success = tmuxService.killSession(name: session.name)
        if success {
            refreshSessions()
        } else {
            lastError = "Failed to kill session '\(session.name)'"
        }
    }

    func renameSession(_ session: TmuxSession, to newName: String) {
        // Update favorites if needed
        if preferencesManager.favorites.contains(session.name) {
            preferencesManager.removeFavorite(session.name)
            preferencesManager.addFavorite(newName)
        }

        // Update groups if needed
        for (groupName, sessionNames) in preferencesManager.groups {
            if sessionNames.contains(session.name) {
                var newNames = sessionNames.filter { $0 != session.name }
                newNames.append(newName)
                preferencesManager.updateGroup(groupName, sessions: newNames)
                break
            }
        }

        let success = tmuxService.renameSession(oldName: session.name, newName: newName)
        if success {
            refreshSessions()
        } else {
            lastError = "Failed to rename session"
        }
    }

    func attachSession(_ session: TmuxSession) {
        preferencesManager.terminalApp.attachToSession(session.name)
    }

    // MARK: - Window Operations

    func createWindow(in session: TmuxSession, name: String? = nil) {
        let success = tmuxService.createWindow(in: session.name, name: name)
        if success {
            refreshSessions()
        } else {
            lastError = "Failed to create window"
        }
    }

    func splitHorizontal(in session: TmuxSession) {
        let success = tmuxService.splitHorizontal(in: session.name)
        if success {
            refreshSessions()
        } else {
            lastError = "Failed to split pane"
        }
    }

    func splitVertical(in session: TmuxSession) {
        let success = tmuxService.splitVertical(in: session.name)
        if success {
            refreshSessions()
        } else {
            lastError = "Failed to split pane"
        }
    }

    // MARK: - Favorites

    func toggleFavorite(_ session: TmuxSession) {
        if preferencesManager.favorites.contains(session.name) {
            preferencesManager.removeFavorite(session.name)
        } else {
            preferencesManager.addFavorite(session.name)
        }
        objectWillChange.send()
    }

    func isFavorite(_ session: TmuxSession) -> Bool {
        preferencesManager.favorites.contains(session.name)
    }

    // MARK: - Groups

    func addToGroup(_ session: TmuxSession, groupName: String) {
        var sessions = preferencesManager.groups[groupName] ?? []
        if !sessions.contains(session.name) {
            sessions.append(session.name)
            preferencesManager.updateGroup(groupName, sessions: sessions)
        }
        objectWillChange.send()
    }

    func removeFromGroup(_ session: TmuxSession, groupName: String) {
        guard var sessions = preferencesManager.groups[groupName] else { return }
        sessions.removeAll { $0 == session.name }
        if sessions.isEmpty {
            preferencesManager.removeGroup(groupName)
        } else {
            preferencesManager.updateGroup(groupName, sessions: sessions)
        }
        objectWillChange.send()
    }

    func createGroup(_ groupName: String, sessions: [TmuxSession] = []) {
        let sessionNames = sessions.map { $0.name }
        preferencesManager.updateGroup(groupName, sessions: sessionNames)
        objectWillChange.send()
    }
}
