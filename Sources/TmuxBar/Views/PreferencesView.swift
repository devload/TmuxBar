import SwiftUI

struct PreferencesView: View {
    @StateObject private var preferencesManager = PreferencesManager.shared
    @StateObject private var sessionManager = SessionManager.shared

    @State private var selectedTab = 0
    @State private var newGroupName = ""
    @State private var showingNewGroupSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)

            terminalTab
                .tabItem {
                    Label("Terminal", systemImage: "terminal")
                }
                .tag(1)

            favoritesTab
                .tabItem {
                    Label("Favorites", systemImage: "star")
                }
                .tag(2)

            groupsTab
                .tabItem {
                    Label("Groups", systemImage: "folder")
                }
                .tag(3)
        }
        .padding(20)
        .frame(width: 450, height: 350)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $preferencesManager.launchAtLogin)

                HStack {
                    Text("Refresh Interval:")
                    Picker("", selection: $preferencesManager.refreshInterval) {
                        Text("1 second").tag(1.0)
                        Text("2 seconds").tag(2.0)
                        Text("3 seconds").tag(3.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
            }

            Section {
                Toggle("Show Window Count", isOn: $preferencesManager.showWindowCount)
                Toggle("Show Attached Indicator", isOn: $preferencesManager.showAttachedIndicator)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Reset to Defaults") {
                    preferencesManager.resetToDefaults()
                }
            }
        }
    }

    // MARK: - Terminal Tab

    private var terminalTab: some View {
        Form {
            Section {
                Text("Default Terminal Application:")
                    .font(.headline)

                Picker("", selection: $preferencesManager.terminalApp) {
                    ForEach(TerminalApp.allCases) { terminal in
                        HStack {
                            Text(terminal.displayName)
                            if !terminal.isInstalled {
                                Text("(Not Installed)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(terminal)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }

            Section {
                Text("Note: Some terminals may require additional permissions to be controlled via AppleScript.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Favorites Tab

    private var favoritesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorite Sessions")
                .font(.headline)

            if preferencesManager.favorites.isEmpty {
                Text("No favorite sessions. Right-click a session to add it to favorites.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List {
                    ForEach(Array(preferencesManager.favorites).sorted(), id: \.self) { name in
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(name)
                            Spacer()
                            Button(action: {
                                preferencesManager.removeFavorite(name)
                            }) {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Text("Tip: Use \u{2318}\u{21E7}1-9 to quickly attach to favorite sessions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Groups Tab

    private var groupsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Session Groups")
                    .font(.headline)
                Spacer()
                Button(action: { showingNewGroupSheet = true }) {
                    Image(systemName: "plus")
                }
            }

            if preferencesManager.groups.isEmpty {
                Text("No groups. Click + to create a group.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List {
                    ForEach(Array(preferencesManager.groups.keys).sorted(), id: \.self) { groupName in
                        DisclosureGroup(groupName) {
                            if let sessions = preferencesManager.groups[groupName] {
                                ForEach(sessions, id: \.self) { sessionName in
                                    HStack {
                                        Text(sessionName)
                                        Spacer()
                                        Button(action: {
                                            let updatedSessions = sessions.filter { $0 != sessionName }
                                            if updatedSessions.isEmpty {
                                                preferencesManager.removeGroup(groupName)
                                            } else {
                                                preferencesManager.updateGroup(groupName, sessions: updatedSessions)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        let groupNames = Array(preferencesManager.groups.keys).sorted()
                        for index in indexSet {
                            preferencesManager.removeGroup(groupNames[index])
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewGroupSheet) {
            newGroupSheet
        }
    }

    private var newGroupSheet: some View {
        VStack(spacing: 16) {
            Text("New Group")
                .font(.headline)

            TextField("Group Name", text: $newGroupName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showingNewGroupSheet = false
                    newGroupName = ""
                }
                Spacer()
                Button("Create") {
                    if !newGroupName.isEmpty {
                        preferencesManager.updateGroup(newGroupName, sessions: [])
                        showingNewGroupSheet = false
                        newGroupName = ""
                    }
                }
                .disabled(newGroupName.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
    }
}
