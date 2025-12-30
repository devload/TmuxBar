import Foundation

struct TmuxWindow: Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var isActive: Bool
    var paneCount: Int
    var panes: [TmuxPane]

    init(id: String, name: String, isActive: Bool, paneCount: Int, panes: [TmuxPane] = []) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.paneCount = paneCount
        self.panes = panes
    }

    static func == (lhs: TmuxWindow, rhs: TmuxWindow) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
