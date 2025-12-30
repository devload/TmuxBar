import Foundation

struct TmuxPane: Identifiable, Equatable, Hashable {
    let id: String
    var isActive: Bool
    var width: Int
    var height: Int
    var currentCommand: String?

    init(id: String, isActive: Bool, width: Int = 0, height: Int = 0, currentCommand: String? = nil) {
        self.id = id
        self.isActive = isActive
        self.width = width
        self.height = height
        self.currentCommand = currentCommand
    }

    static func == (lhs: TmuxPane, rhs: TmuxPane) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
