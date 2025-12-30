import Foundation
import Combine
import ServiceManagement

final class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()

    private let defaults = UserDefaults.standard

    @Published var terminalApp: TerminalApp {
        didSet {
            defaults.set(terminalApp.rawValue, forKey: Constants.UserDefaultsKeys.terminalApp)
        }
    }

    @Published var refreshInterval: TimeInterval {
        didSet {
            defaults.set(refreshInterval, forKey: Constants.UserDefaultsKeys.refreshInterval)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Constants.UserDefaultsKeys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    @Published private(set) var favorites: Set<String> {
        didSet {
            defaults.set(Array(favorites), forKey: Constants.UserDefaultsKeys.favorites)
        }
    }

    @Published private(set) var groups: [String: [String]] {
        didSet {
            defaults.set(groups, forKey: Constants.UserDefaultsKeys.groups)
        }
    }

    @Published var showWindowCount: Bool {
        didSet {
            defaults.set(showWindowCount, forKey: Constants.UserDefaultsKeys.showWindowCount)
        }
    }

    @Published var showAttachedIndicator: Bool {
        didSet {
            defaults.set(showAttachedIndicator, forKey: Constants.UserDefaultsKeys.showAttachedIndicator)
        }
    }

    private init() {
        // Load terminal app
        if let terminalRaw = defaults.string(forKey: Constants.UserDefaultsKeys.terminalApp),
           let terminal = TerminalApp(rawValue: terminalRaw) {
            self.terminalApp = terminal
        } else {
            self.terminalApp = Constants.Defaults.terminalApp
        }

        // Load refresh interval
        let interval = defaults.double(forKey: Constants.UserDefaultsKeys.refreshInterval)
        self.refreshInterval = interval > 0 ? interval : Constants.Defaults.refreshInterval

        // Load launch at login
        self.launchAtLogin = defaults.bool(forKey: Constants.UserDefaultsKeys.launchAtLogin)

        // Load favorites
        let favoriteArray = defaults.stringArray(forKey: Constants.UserDefaultsKeys.favorites) ?? []
        self.favorites = Set(favoriteArray)

        // Load groups
        self.groups = (defaults.dictionary(forKey: Constants.UserDefaultsKeys.groups) as? [String: [String]]) ?? [:]

        // Load display options
        self.showWindowCount = defaults.object(forKey: Constants.UserDefaultsKeys.showWindowCount) as? Bool ?? Constants.Defaults.showWindowCount
        self.showAttachedIndicator = defaults.object(forKey: Constants.UserDefaultsKeys.showAttachedIndicator) as? Bool ?? Constants.Defaults.showAttachedIndicator
    }

    // MARK: - Favorites

    func addFavorite(_ sessionName: String) {
        favorites.insert(sessionName)
    }

    func removeFavorite(_ sessionName: String) {
        favorites.remove(sessionName)
    }

    func isFavorite(_ sessionName: String) -> Bool {
        favorites.contains(sessionName)
    }

    // MARK: - Groups

    func updateGroup(_ name: String, sessions: [String]) {
        groups[name] = sessions
    }

    func removeGroup(_ name: String) {
        groups.removeValue(forKey: name)
    }

    func renameGroup(_ oldName: String, to newName: String) {
        guard let sessions = groups[oldName] else { return }
        groups.removeValue(forKey: oldName)
        groups[newName] = sessions
    }

    // MARK: - Launch at Login

    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }

    // MARK: - Reset

    func resetToDefaults() {
        terminalApp = Constants.Defaults.terminalApp
        refreshInterval = Constants.Defaults.refreshInterval
        launchAtLogin = Constants.Defaults.launchAtLogin
        favorites = []
        groups = [:]
        showWindowCount = Constants.Defaults.showWindowCount
        showAttachedIndicator = Constants.Defaults.showAttachedIndicator
    }
}
