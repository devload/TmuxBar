import Foundation

enum Constants {
    static let appName = "TmuxBar"
    static let bundleIdentifier = "com.tmuxbar.app"

    enum UserDefaultsKeys {
        static let terminalApp = "terminalApp"
        static let refreshInterval = "refreshInterval"
        static let launchAtLogin = "launchAtLogin"
        static let favorites = "favorites"
        static let groups = "groups"
        static let showWindowCount = "showWindowCount"
        static let showAttachedIndicator = "showAttachedIndicator"
    }

    enum Defaults {
        static let terminalApp = TerminalApp.terminal
        static let refreshInterval: TimeInterval = 3.0
        static let launchAtLogin = true
        static let showWindowCount = true
        static let showAttachedIndicator = true
    }
}

enum TerminalApp: String, CaseIterable, Identifiable {
    case terminal = "Terminal"
    case iterm2 = "iTerm2"
    case alacritty = "Alacritty"
    case warp = "Warp"
    case kitty = "Kitty"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var isInstalled: Bool {
        switch self {
        case .terminal:
            return true // Always available on macOS
        case .iterm2:
            return FileManager.default.fileExists(atPath: "/Applications/iTerm.app")
        case .alacritty:
            return Shell.commandExists("alacritty")
        case .warp:
            return FileManager.default.fileExists(atPath: "/Applications/Warp.app")
        case .kitty:
            return Shell.commandExists("kitty")
        }
    }

    func attachToSession(_ sessionName: String) {
        switch self {
        case .terminal:
            attachViaTerminal(sessionName)
        case .iterm2:
            attachViaITerm2(sessionName)
        case .alacritty:
            attachViaAlacritty(sessionName)
        case .warp:
            attachViaWarp(sessionName)
        case .kitty:
            attachViaKitty(sessionName)
        }
    }

    private func attachViaTerminal(_ sessionName: String) {
        let script = """
        tell application "Terminal"
            activate
            do script "tmux attach -t '\(sessionName)'"
        end tell
        """
        runAppleScript(script)
    }

    private func attachViaITerm2(_ sessionName: String) {
        let script = """
        tell application "iTerm2"
            activate
            create window with default profile command "tmux attach -t '\(sessionName)'"
        end tell
        """
        runAppleScript(script)
    }

    private func attachViaAlacritty(_ sessionName: String) {
        let path = Shell.commandPath("alacritty") ?? "/usr/local/bin/alacritty"
        runProcess(path, arguments: ["-e", "tmux", "attach", "-t", sessionName])
    }

    private func attachViaWarp(_ sessionName: String) {
        // Warp doesn't have great CLI support yet, so we use open
        let script = """
        tell application "Warp"
            activate
        end tell
        """
        runAppleScript(script)

        // After activating, we need to send the command
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let typeScript = """
            tell application "System Events"
                tell process "Warp"
                    keystroke "tmux attach -t '\(sessionName)'"
                    keystroke return
                end tell
            end tell
            """
            self.runAppleScript(typeScript)
        }
    }

    private func attachViaKitty(_ sessionName: String) {
        let path = Shell.commandPath("kitty") ?? "/usr/local/bin/kitty"
        runProcess(path, arguments: ["tmux", "attach", "-t", sessionName])
    }

    private func runAppleScript(_ source: String) {
        var error: NSDictionary?
        if let script = NSAppleScript(source: source) {
            script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            }
        }
    }

    private func runProcess(_ path: String, arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        do {
            try process.run()
        } catch {
            print("Failed to run process: \(error)")
        }
    }
}
