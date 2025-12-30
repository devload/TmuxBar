import Foundation

enum PaneLayout: String, Codable, CaseIterable, Identifiable {
    case single = "Single"
    case horizontalSplit = "Horizontal Split"
    case verticalSplit = "Vertical Split"
    case fourPane = "Four Panes"
    case mainWithSidebar = "Main + Sidebar"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .single: return "rectangle"
        case .horizontalSplit: return "rectangle.split.1x2"
        case .verticalSplit: return "rectangle.split.2x1"
        case .fourPane: return "square.grid.2x2"
        case .mainWithSidebar: return "sidebar.right"
        }
    }

    var paneCount: Int {
        switch self {
        case .single: return 1
        case .horizontalSplit, .verticalSplit, .mainWithSidebar: return 2
        case .fourPane: return 4
        }
    }
}

struct WindowTemplate: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var layout: PaneLayout
    var commands: [String] // Commands to run in each pane

    init(name: String, layout: PaneLayout = .single, commands: [String] = []) {
        self.name = name
        self.layout = layout
        // Ensure commands array matches pane count
        self.commands = commands + Array(repeating: "", count: max(0, layout.paneCount - commands.count))
    }
}

struct SessionTemplate: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var description: String
    var icon: String
    var workingDirectory: String?
    var windows: [WindowTemplate]
    var isBuiltIn: Bool

    init(name: String, description: String, icon: String = "terminal", workingDirectory: String? = nil, windows: [WindowTemplate], isBuiltIn: Bool = false) {
        self.name = name
        self.description = description
        self.icon = icon
        self.workingDirectory = workingDirectory
        self.windows = windows
        self.isBuiltIn = isBuiltIn
    }

    // MARK: - Built-in Templates

    static let development = SessionTemplate(
        name: "Development",
        description: "Editor + Terminal + Git status",
        icon: "hammer",
        windows: [
            WindowTemplate(name: "editor", layout: .single, commands: ["nvim ."]),
            WindowTemplate(name: "terminal", layout: .horizontalSplit, commands: ["", "git status"]),
        ],
        isBuiltIn: true
    )

    static let webDev = SessionTemplate(
        name: "Web Development",
        description: "Server + Client + Logs",
        icon: "globe",
        windows: [
            WindowTemplate(name: "server", layout: .single, commands: ["npm run dev"]),
            WindowTemplate(name: "client", layout: .single, commands: ["npm run client"]),
            WindowTemplate(name: "logs", layout: .verticalSplit, commands: ["tail -f logs/app.log", "tail -f logs/error.log"]),
        ],
        isBuiltIn: true
    )

    static let monitoring = SessionTemplate(
        name: "System Monitoring",
        description: "htop + logs + network",
        icon: "chart.line.uptrend.xyaxis",
        windows: [
            WindowTemplate(name: "monitor", layout: .fourPane, commands: ["htop", "watch -n 1 df -h", "tail -f /var/log/system.log", "netstat -an | head -20"]),
        ],
        isBuiltIn: true
    )

    static let ssh = SessionTemplate(
        name: "SSH Session",
        description: "Multi-server management",
        icon: "network",
        windows: [
            WindowTemplate(name: "server1", layout: .single, commands: [""]),
            WindowTemplate(name: "server2", layout: .single, commands: [""]),
            WindowTemplate(name: "local", layout: .single, commands: [""]),
        ],
        isBuiltIn: true
    )

    static let docker = SessionTemplate(
        name: "Docker Management",
        description: "Containers + Logs + Shell",
        icon: "shippingbox",
        windows: [
            WindowTemplate(name: "containers", layout: .single, commands: ["docker ps -a"]),
            WindowTemplate(name: "logs", layout: .single, commands: ["docker-compose logs -f"]),
            WindowTemplate(name: "shell", layout: .single, commands: [""]),
        ],
        isBuiltIn: true
    )

    static let builtInTemplates: [SessionTemplate] = [
        .development,
        .webDev,
        .monitoring,
        .ssh,
        .docker
    ]
}
