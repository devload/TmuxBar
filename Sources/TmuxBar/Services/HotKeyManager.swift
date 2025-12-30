import Foundation
import AppKit
import Carbon
import HotKey

final class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()

    private var openMenuHotKey: HotKey?
    private var newSessionHotKey: HotKey?
    private var quickAttachHotKeys: [HotKey] = []

    var onOpenMenu: (() -> Void)?
    var onNewSession: (() -> Void)?
    var onQuickAttach: ((Int) -> Void)?

    private init() {}

    func registerHotKeys() {
        // Cmd+Shift+T - Open menu
        openMenuHotKey = HotKey(key: .t, modifiers: [.command, .shift])
        openMenuHotKey?.keyDownHandler = { [weak self] in
            self?.onOpenMenu?()
        }

        // Cmd+Shift+N - New session
        newSessionHotKey = HotKey(key: .n, modifiers: [.command, .shift])
        newSessionHotKey?.keyDownHandler = { [weak self] in
            self?.onNewSession?()
        }

        // Cmd+Shift+1-9 - Quick attach to favorites
        let numberKeys: [Key] = [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine]
        for (index, key) in numberKeys.enumerated() {
            let hotKey = HotKey(key: key, modifiers: [.command, .shift])
            hotKey.keyDownHandler = { [weak self] in
                self?.onQuickAttach?(index)
            }
            quickAttachHotKeys.append(hotKey)
        }
    }

    func unregisterHotKeys() {
        openMenuHotKey = nil
        newSessionHotKey = nil
        quickAttachHotKeys.removeAll()
    }

    func updateHotKey(for action: HotKeyAction, key: Key, modifiers: NSEvent.ModifierFlags) {
        switch action {
        case .openMenu:
            openMenuHotKey = HotKey(key: key, modifiers: modifiers)
            openMenuHotKey?.keyDownHandler = { [weak self] in
                self?.onOpenMenu?()
            }
        case .newSession:
            newSessionHotKey = HotKey(key: key, modifiers: modifiers)
            newSessionHotKey?.keyDownHandler = { [weak self] in
                self?.onNewSession?()
            }
        }
    }
}

enum HotKeyAction {
    case openMenu
    case newSession
}
