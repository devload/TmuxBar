import AppKit
import SwiftUI
import Combine

// Custom panel that can become key window for text input
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var sessionManager: SessionManager!
    private var preferencesManager: PreferencesManager!
    private var hotKeyManager: HotKeyManager!
    private var cancellables = Set<AnyCancellable>()
    private var preferencesWindow: NSWindow?
    private var newSessionWindow: NSWindow?
    private var templateWindow: NSWindow?
    private var previewPopover: NSPopover?
    private var previewSession: TmuxSession?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check for duplicate instance using process name
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let runningApps = NSWorkspace.shared.runningApplications
        let tmuxBarApps = runningApps.filter {
            ($0.localizedName == "TmuxBar" || $0.executableURL?.lastPathComponent == "TmuxBar")
            && $0.processIdentifier != currentPID
        }
        if !tmuxBarApps.isEmpty {
            // Another instance is already running
            NSApp.terminate(nil)
            return
        }

        // Hide dock icon - menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Initialize managers
        preferencesManager = PreferencesManager.shared
        sessionManager = SessionManager.shared
        hotKeyManager = HotKeyManager.shared

        // Setup status bar
        setupStatusBar()

        // Setup hot keys
        setupHotKeys()

        // Start session monitoring
        sessionManager.startMonitoring()

        // Observe session changes
        sessionManager.$sessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running even when all windows are closed (menu bar app)
        return false
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "TmuxBar")
            button.image?.size = NSSize(width: 18, height: 18)
        }

        updateMenu()
    }

    private func setupHotKeys() {
        hotKeyManager.registerHotKeys()

        hotKeyManager.onOpenMenu = { [weak self] in
            self?.statusItem.button?.performClick(nil)
        }

        hotKeyManager.onNewSession = { [weak self] in
            self?.showNewSessionWindow()
        }

        hotKeyManager.onQuickAttach = { [weak self] index in
            self?.attachFavoriteSession(at: index)
        }
    }

    private func updateMenu() {
        let menu = NSMenu()

        let favorites = sessionManager.favoriteSessions
        let groups = sessionManager.groupedSessions
        let others = sessionManager.ungroupedSessions.filter { !favorites.contains($0) }

        // Favorites section
        if !favorites.isEmpty {
            for session in favorites {
                menu.addItem(createSessionMenuItem(session, isFavorite: true))
            }
            menu.addItem(NSMenuItem.separator())
        }

        // Grouped sessions
        for (groupName, sessions) in groups {
            let groupItem = NSMenuItem(title: "\u{1F4C1} \(groupName)", action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            for session in sessions {
                submenu.addItem(createSessionMenuItem(session, isFavorite: false))
            }
            groupItem.submenu = submenu
            menu.addItem(groupItem)
        }

        if !groups.isEmpty && !others.isEmpty {
            menu.addItem(NSMenuItem.separator())
        }

        // Other sessions
        if !others.isEmpty {
            let othersItem = NSMenuItem(title: "Sessions", action: nil, keyEquivalent: "")
            othersItem.isEnabled = false
            menu.addItem(othersItem)

            for session in others {
                menu.addItem(createSessionMenuItem(session, isFavorite: false))
            }
        }

        // No sessions message
        if sessionManager.sessions.isEmpty {
            let noSessionItem = NSMenuItem(title: "No tmux sessions", action: nil, keyEquivalent: "")
            noSessionItem.isEnabled = false
            menu.addItem(noSessionItem)
        }

        menu.addItem(NSMenuItem.separator())

        // New Session
        let newSessionItem = NSMenuItem(title: "New Session...", action: #selector(showNewSessionWindow), keyEquivalent: "n")
        newSessionItem.keyEquivalentModifierMask = [.command, .shift]
        newSessionItem.target = self
        menu.addItem(newSessionItem)

        // New from Template
        let templateItem = NSMenuItem(title: "New from Template...", action: #selector(showTemplateWindow), keyEquivalent: "t")
        templateItem.keyEquivalentModifierMask = [.command, .shift]
        templateItem.target = self
        menu.addItem(templateItem)

        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Refresh
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshSessions), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        // Quit
        let quitItem = NSMenuItem(title: "Quit TmuxBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func createSessionMenuItem(_ session: TmuxSession, isFavorite: Bool) -> NSMenuItem {
        let prefix = isFavorite ? "\u{2B50} " : ""
        let attachedIndicator = session.isAttached ? " \u{1F7E2}" : ""
        let title = "\(prefix)\(session.name) (\(session.windowCount) windows)\(attachedIndicator)"

        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")

        let submenu = NSMenu()

        // Preview
        let previewItem = NSMenuItem(title: "Preview...", action: #selector(showPreview(_:)), keyEquivalent: "")
        previewItem.target = self
        previewItem.representedObject = session
        submenu.addItem(previewItem)

        submenu.addItem(NSMenuItem.separator())

        // Attach
        let attachItem = NSMenuItem(title: session.isAttached ? "Already Attached" : "Attach", action: #selector(attachSession(_:)), keyEquivalent: "")
        attachItem.target = self
        attachItem.representedObject = session
        attachItem.isEnabled = !session.isAttached
        submenu.addItem(attachItem)

        // Windows submenu
        if !session.windows.isEmpty {
            submenu.addItem(NSMenuItem.separator())
            let windowsItem = NSMenuItem(title: "Windows", action: nil, keyEquivalent: "")
            let windowsSubmenu = NSMenu()
            for window in session.windows {
                let windowItem = NSMenuItem(title: "\(window.name)\(window.isActive ? " \u{2713}" : "")", action: nil, keyEquivalent: "")
                windowsSubmenu.addItem(windowItem)
            }
            windowsItem.submenu = windowsSubmenu
            submenu.addItem(windowsItem)
        }

        submenu.addItem(NSMenuItem.separator())

        // New Window
        let newWindowItem = NSMenuItem(title: "New Window", action: #selector(newWindow(_:)), keyEquivalent: "")
        newWindowItem.target = self
        newWindowItem.representedObject = session
        submenu.addItem(newWindowItem)

        // Rename
        let renameItem = NSMenuItem(title: "Rename...", action: #selector(renameSession(_:)), keyEquivalent: "")
        renameItem.target = self
        renameItem.representedObject = session
        submenu.addItem(renameItem)

        // Toggle Favorite
        let favTitle = isFavorite ? "Remove from Favorites" : "Add to Favorites"
        let favItem = NSMenuItem(title: favTitle, action: #selector(toggleFavorite(_:)), keyEquivalent: "")
        favItem.target = self
        favItem.representedObject = session
        submenu.addItem(favItem)

        submenu.addItem(NSMenuItem.separator())

        // Kill Session
        let killItem = NSMenuItem(title: "Kill Session", action: #selector(killSession(_:)), keyEquivalent: "")
        killItem.target = self
        killItem.representedObject = session
        submenu.addItem(killItem)

        item.submenu = submenu
        return item
    }

    // MARK: - Actions

    @objc private func attachSession(_ sender: NSMenuItem) {
        guard let session = sender.representedObject as? TmuxSession else { return }
        sessionManager.attachSession(session)
    }

    @objc private func newWindow(_ sender: NSMenuItem) {
        guard let session = sender.representedObject as? TmuxSession else { return }
        sessionManager.createWindow(in: session)
    }

    @objc private func renameSession(_ sender: NSMenuItem) {
        guard let session = sender.representedObject as? TmuxSession else { return }

        let alert = NSAlert()
        alert.messageText = "Rename Session"
        alert.informativeText = "Enter new name for '\(session.name)':"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = session.name
        alert.accessoryView = textField

        if alert.runModal() == .alertFirstButtonReturn {
            let newName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newName.isEmpty && newName != session.name {
                sessionManager.renameSession(session, to: newName)
            }
        }
    }

    @objc private func toggleFavorite(_ sender: NSMenuItem) {
        guard let session = sender.representedObject as? TmuxSession else { return }
        sessionManager.toggleFavorite(session)
    }

    @objc private func killSession(_ sender: NSMenuItem) {
        guard let session = sender.representedObject as? TmuxSession else { return }

        let alert = NSAlert()
        alert.messageText = "Kill Session?"
        alert.informativeText = "Are you sure you want to kill '\(session.name)'? This cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Kill")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            sessionManager.killSession(session)
        }
    }

    @objc private func showNewSessionWindow() {
        if newSessionWindow == nil {
            let view = NewSessionView { [weak self] in
                self?.newSessionWindow?.close()
                self?.newSessionWindow = nil
            }

            newSessionWindow = KeyablePanel(
                contentRect: NSRect(x: 0, y: 0, width: 350, height: 200),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newSessionWindow?.title = "New Session"
            newSessionWindow?.contentView = NSHostingView(rootView: view)
            newSessionWindow?.center()
            newSessionWindow?.isReleasedWhenClosed = false
            newSessionWindow?.level = .floating
            newSessionWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }

        NSApp.activate(ignoringOtherApps: true)
        newSessionWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func showTemplateWindow() {
        if templateWindow == nil {
            let view = TemplatePickerView(
                onDismiss: { [weak self] in
                    self?.templateWindow?.close()
                    self?.templateWindow = nil
                },
                onCreateSession: { [weak self] sessionName in
                    self?.sessionManager.refreshSessions()
                }
            )

            templateWindow = KeyablePanel(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            templateWindow?.title = "New from Template"
            templateWindow?.contentView = NSHostingView(rootView: view)
            templateWindow?.center()
            templateWindow?.isReleasedWhenClosed = false
            templateWindow?.level = .floating
            templateWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }

        NSApp.activate(ignoringOtherApps: true)
        templateWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func showPreview(_ sender: NSMenuItem) {
        guard let session = sender.representedObject as? TmuxSession else { return }

        // Close existing popover
        previewPopover?.close()

        let previewView = SessionPreviewView(session: session)

        previewPopover = NSPopover()
        previewPopover?.contentSize = NSSize(width: 350, height: 350)
        previewPopover?.behavior = .transient
        previewPopover?.animates = true
        previewPopover?.contentViewController = NSHostingController(rootView: previewView)

        // Show relative to status item
        if let button = statusItem.button {
            previewPopover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc private func showPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = KeyablePanel(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            preferencesWindow?.title = "TmuxBar Preferences"
            preferencesWindow?.contentView = NSHostingView(rootView: PreferencesView())
            preferencesWindow?.center()
            preferencesWindow?.isReleasedWhenClosed = false
            preferencesWindow?.level = .floating
            preferencesWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }

        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func refreshSessions() {
        sessionManager.refreshSessions()
    }

    private func attachFavoriteSession(at index: Int) {
        let favorites = sessionManager.favoriteSessions
        if index < favorites.count {
            sessionManager.attachSession(favorites[index])
        }
    }
}
