import Foundation

struct TmuxSession: Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var windowCount: Int
    var isAttached: Bool
    var windows: [TmuxWindow]
    var group: String?

    init(id: String, name: String, windowCount: Int, isAttached: Bool, windows: [TmuxWindow] = [], group: String? = nil) {
        self.id = id
        self.name = name
        self.windowCount = windowCount
        self.isAttached = isAttached
        self.windows = windows
        self.group = group
    }

    static func == (lhs: TmuxSession, rhs: TmuxSession) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
