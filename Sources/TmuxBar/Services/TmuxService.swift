import Foundation

final class TmuxService {
    static let shared = TmuxService()

    private let tmuxPath: String
    let isTmuxInstalled: Bool

    private init() {
        // Find tmux path
        self.isTmuxInstalled = Shell.commandExists("tmux")
        self.tmuxPath = Shell.commandPath("tmux") ?? "/opt/homebrew/bin/tmux"
    }

    /// Check if tmux is installed
    func checkTmuxInstallation() -> Bool {
        return isTmuxInstalled
    }

    // MARK: - Session Operations

    /// List all tmux sessions
    func listSessions() -> [TmuxSession] {
        do {
            let format = "#{session_id}:#{session_name}:#{session_windows}:#{session_attached}"
            let output = try Shell.run("\(tmuxPath) list-sessions -F '\(format)'")

            guard !output.isEmpty else { return [] }

            return output.components(separatedBy: "\n").compactMap { line -> TmuxSession? in
                let parts = line.components(separatedBy: ":")
                guard parts.count >= 4 else { return nil }

                let id = parts[0]
                let name = parts[1]
                let windowCount = Int(parts[2]) ?? 0
                let isAttached = parts[3] == "1"

                var session = TmuxSession(id: id, name: name, windowCount: windowCount, isAttached: isAttached)
                session.windows = listWindows(for: name)
                return session
            }
        } catch {
            print("Failed to list sessions: \(error)")
            return []
        }
    }

    /// Create a new session
    func createSession(name: String, directory: String? = nil) -> Bool {
        do {
            var command = "\(tmuxPath) new-session -d -s '\(name)'"
            if let dir = directory {
                command += " -c '\(dir)'"
            }
            try Shell.run(command)
            return true
        } catch {
            print("Failed to create session: \(error)")
            return false
        }
    }

    /// Kill a session
    func killSession(name: String) -> Bool {
        do {
            try Shell.run("\(tmuxPath) kill-session -t '\(name)'")
            return true
        } catch {
            print("Failed to kill session: \(error)")
            return false
        }
    }

    /// Rename a session
    func renameSession(oldName: String, newName: String) -> Bool {
        do {
            try Shell.run("\(tmuxPath) rename-session -t '\(oldName)' '\(newName)'")
            return true
        } catch {
            print("Failed to rename session: \(error)")
            return false
        }
    }

    // MARK: - Window Operations

    /// List windows in a session
    func listWindows(for sessionName: String) -> [TmuxWindow] {
        do {
            let format = "#{window_id}:#{window_name}:#{window_active}:#{window_panes}"
            let output = try Shell.run("\(tmuxPath) list-windows -t '\(sessionName)' -F '\(format)'")

            guard !output.isEmpty else { return [] }

            return output.components(separatedBy: "\n").compactMap { line -> TmuxWindow? in
                let parts = line.components(separatedBy: ":")
                guard parts.count >= 4 else { return nil }

                let id = parts[0]
                let name = parts[1]
                let isActive = parts[2] == "1"
                let paneCount = Int(parts[3]) ?? 0

                return TmuxWindow(id: id, name: name, isActive: isActive, paneCount: paneCount)
            }
        } catch {
            print("Failed to list windows: \(error)")
            return []
        }
    }

    /// Create a new window in a session
    func createWindow(in sessionName: String, name: String? = nil) -> Bool {
        do {
            var command = "\(tmuxPath) new-window -t '\(sessionName)'"
            if let windowName = name {
                command += " -n '\(windowName)'"
            }
            try Shell.run(command)
            return true
        } catch {
            print("Failed to create window: \(error)")
            return false
        }
    }

    /// Rename a window
    func renameWindow(in sessionName: String, windowId: String, newName: String) -> Bool {
        do {
            try Shell.run("\(tmuxPath) rename-window -t '\(sessionName):\(windowId)' '\(newName)'")
            return true
        } catch {
            print("Failed to rename window: \(error)")
            return false
        }
    }

    /// Kill a window
    func killWindow(in sessionName: String, windowId: String) -> Bool {
        do {
            try Shell.run("\(tmuxPath) kill-window -t '\(sessionName):\(windowId)'")
            return true
        } catch {
            print("Failed to kill window: \(error)")
            return false
        }
    }

    // MARK: - Pane Operations

    /// Split a pane horizontally
    func splitHorizontal(in sessionName: String, windowId: String? = nil) -> Bool {
        do {
            let target = windowId != nil ? "\(sessionName):\(windowId!)" : sessionName
            try Shell.run("\(tmuxPath) split-window -h -t '\(target)'")
            return true
        } catch {
            print("Failed to split horizontally: \(error)")
            return false
        }
    }

    /// Split a pane vertically
    func splitVertical(in sessionName: String, windowId: String? = nil) -> Bool {
        do {
            let target = windowId != nil ? "\(sessionName):\(windowId!)" : sessionName
            try Shell.run("\(tmuxPath) split-window -v -t '\(target)'")
            return true
        } catch {
            print("Failed to split vertically: \(error)")
            return false
        }
    }

    // MARK: - Server Operations

    /// Check if tmux server is running
    func isServerRunning() -> Bool {
        do {
            try Shell.run("\(tmuxPath) list-sessions")
            return true
        } catch {
            return false
        }
    }

    /// Start tmux server
    func startServer() -> Bool {
        do {
            try Shell.run("\(tmuxPath) start-server")
            return true
        } catch {
            print("Failed to start server: \(error)")
            return false
        }
    }

    /// Kill tmux server
    func killServer() -> Bool {
        do {
            try Shell.run("\(tmuxPath) kill-server")
            return true
        } catch {
            print("Failed to kill server: \(error)")
            return false
        }
    }

    // MARK: - Preview Operations

    /// Capture pane content for preview
    func capturePane(sessionName: String, windowIndex: Int = 0, paneIndex: Int = 0, lines: Int = 30) -> String {
        do {
            let target = "\(sessionName):\(windowIndex).\(paneIndex)"
            let output = try Shell.run("\(tmuxPath) capture-pane -t '\(target)' -p -S -\(lines)")
            return output
        } catch {
            print("Failed to capture pane: \(error)")
            return ""
        }
    }

    /// Get current command running in pane
    func getCurrentCommand(sessionName: String, windowIndex: Int = 0, paneIndex: Int = 0) -> String {
        do {
            let target = "\(sessionName):\(windowIndex).\(paneIndex)"
            let output = try Shell.run("\(tmuxPath) display-message -t '\(target)' -p '#{pane_current_command}'")
            return output
        } catch {
            return ""
        }
    }

    /// Get pane current path
    func getCurrentPath(sessionName: String, windowIndex: Int = 0, paneIndex: Int = 0) -> String {
        do {
            let target = "\(sessionName):\(windowIndex).\(paneIndex)"
            let output = try Shell.run("\(tmuxPath) display-message -t '\(target)' -p '#{pane_current_path}'")
            return output
        } catch {
            return ""
        }
    }

    // MARK: - Template Operations

    /// Create session from template
    func createSessionFromTemplate(_ template: SessionTemplate, name: String) -> Bool {
        // Create base session
        guard createSession(name: name, directory: template.workingDirectory) else {
            return false
        }

        // Apply template layout
        for (index, window) in template.windows.enumerated() {
            if index > 0 {
                // Create additional windows
                _ = createWindow(in: name, name: window.name)
            } else {
                // Rename first window
                do {
                    try Shell.run("\(tmuxPath) rename-window -t '\(name):0' '\(window.name)'")
                } catch {
                    print("Failed to rename window: \(error)")
                }
            }

            // Create panes according to layout
            let windowTarget = "\(name):\(index)"
            switch window.layout {
            case .single:
                break // Default, no splits needed
            case .horizontalSplit:
                _ = splitHorizontal(in: name, windowId: "\(index)")
            case .verticalSplit:
                _ = splitVertical(in: name, windowId: "\(index)")
            case .fourPane:
                _ = splitHorizontal(in: name, windowId: "\(index)")
                _ = splitVertical(in: name, windowId: "\(index)")
                do {
                    try Shell.run("\(tmuxPath) select-pane -t '\(windowTarget).0'")
                    _ = splitVertical(in: name, windowId: "\(index)")
                } catch {}
            case .mainWithSidebar:
                _ = splitHorizontal(in: name, windowId: "\(index)")
                do {
                    try Shell.run("\(tmuxPath) resize-pane -t '\(windowTarget).1' -x 40")
                } catch {}
            }

            // Run initial commands
            for (paneIndex, command) in window.commands.enumerated() {
                if !command.isEmpty {
                    do {
                        try Shell.run("\(tmuxPath) send-keys -t '\(windowTarget).\(paneIndex)' '\(command)' Enter")
                    } catch {
                        print("Failed to send command: \(error)")
                    }
                }
            }
        }

        return true
    }
}
