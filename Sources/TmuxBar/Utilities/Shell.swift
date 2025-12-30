import Foundation

struct Shell {
    enum ShellError: Error {
        case executionFailed(String)
        case commandNotFound(String)
    }

    /// Execute a shell command and return the output
    @discardableResult
    static func run(_ command: String, arguments: [String] = []) throws -> String {
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = pipe
        process.standardError = errorPipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", ([command] + arguments).joined(separator: " ")]

        // Include common paths for tmux
        var environment = ProcessInfo.processInfo.environment
        let additionalPaths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]
        let currentPath = environment["PATH"] ?? ""
        environment["PATH"] = (additionalPaths + [currentPath]).joined(separator: ":")
        process.environment = environment

        try process.run()
        process.waitUntilExit()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus != 0 {
            // tmux returns non-zero when no server/sessions exist, which is fine
            if errorOutput.contains("no server running") || errorOutput.contains("no sessions") {
                return ""
            }
            throw ShellError.executionFailed(errorOutput.isEmpty ? "Command failed with exit code \(process.terminationStatus)" : errorOutput)
        }

        return output
    }

    /// Execute a shell command asynchronously
    static func runAsync(_ command: String, arguments: [String] = [], completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try run(command, arguments: arguments)
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Check if a command exists in PATH
    static func commandExists(_ command: String) -> Bool {
        do {
            let result = try run("which \(command)")
            return !result.isEmpty
        } catch {
            return false
        }
    }

    /// Get the full path of a command
    static func commandPath(_ command: String) -> String? {
        do {
            let result = try run("which \(command)")
            return result.isEmpty ? nil : result
        } catch {
            return nil
        }
    }
}
