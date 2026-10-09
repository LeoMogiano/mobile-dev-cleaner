import Foundation

protocol TrashServicing: Sendable {
    /// Moves to user's Trash. Returns resulting URL in Trash or nil if path not found.
    func moveToTrash(_ url: URL) async throws -> URL?
    /// Permanently removes file (when user disables Trash).
    func remove(_ url: URL) async throws
}

struct TrashService: TrashServicing {
    func moveToTrash(_ url: URL) async throws -> URL? {
        var resultingURL: NSURL?
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
            return resultingURL as URL?
        } catch {
            let nsError = error as NSError
            if nsError.code == NSFileNoSuchFileError {
                return nil
            }
            throw error
        }
    }

    func remove(_ url: URL) async throws {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            let nsError = error as NSError
            if nsError.code == NSFileNoSuchFileError {
                return
            }
            throw error
        }
    }
}
