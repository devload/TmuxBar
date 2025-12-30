import Foundation
import Combine

final class TemplateManager: ObservableObject {
    static let shared = TemplateManager()

    @Published private(set) var customTemplates: [SessionTemplate] = []

    private let defaults = UserDefaults.standard
    private let templatesKey = "customTemplates"

    var allTemplates: [SessionTemplate] {
        SessionTemplate.builtInTemplates + customTemplates
    }

    private init() {
        loadCustomTemplates()
    }

    // MARK: - Persistence

    private func loadCustomTemplates() {
        guard let data = defaults.data(forKey: templatesKey),
              let templates = try? JSONDecoder().decode([SessionTemplate].self, from: data) else {
            return
        }
        customTemplates = templates
    }

    private func saveCustomTemplates() {
        guard let data = try? JSONEncoder().encode(customTemplates) else { return }
        defaults.set(data, forKey: templatesKey)
    }

    // MARK: - CRUD Operations

    func addTemplate(_ template: SessionTemplate) {
        var newTemplate = template
        newTemplate.isBuiltIn = false
        customTemplates.append(newTemplate)
        saveCustomTemplates()
    }

    func updateTemplate(_ template: SessionTemplate) {
        guard let index = customTemplates.firstIndex(where: { $0.id == template.id }) else { return }
        customTemplates[index] = template
        saveCustomTemplates()
    }

    func deleteTemplate(_ template: SessionTemplate) {
        guard !template.isBuiltIn else { return }
        customTemplates.removeAll { $0.id == template.id }
        saveCustomTemplates()
    }

    func duplicateTemplate(_ template: SessionTemplate) -> SessionTemplate {
        var newTemplate = template
        newTemplate.id = UUID()
        newTemplate.name = "\(template.name) Copy"
        newTemplate.isBuiltIn = false
        customTemplates.append(newTemplate)
        saveCustomTemplates()
        return newTemplate
    }

    // MARK: - Export/Import

    func exportTemplates() -> Data? {
        try? JSONEncoder().encode(customTemplates)
    }

    func importTemplates(from data: Data) -> Bool {
        guard let templates = try? JSONDecoder().decode([SessionTemplate].self, from: data) else {
            return false
        }

        for var template in templates {
            template.id = UUID()
            template.isBuiltIn = false
            customTemplates.append(template)
        }

        saveCustomTemplates()
        return true
    }
}
