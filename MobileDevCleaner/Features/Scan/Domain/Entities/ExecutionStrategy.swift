import Foundation

enum ExecutionStrategy: Sendable, Hashable {
    case remove(URL)
    case command(executable: String, arguments: [String])

    /// Shell form shown in "Comandos que se ejecutarán".
    func commandLine(movesToTrash: Bool) -> String {
        switch self {
        case .remove(let url):
            movesToTrash ? "mv \"\(url.path)\" ~/.Trash/" : "rm -rf \"\(url.path)\""
        case .command(let executable, let arguments):
            ([executable] + arguments.map { $0.contains(" ") ? "\"\($0)\"" : $0 }).joined(separator: " ")
        }
    }
}
