import Foundation

func waitSeconds(_ seconds: TimeInterval) async -> Bool {
    do {
        try await Task.sleep(for: .seconds(seconds))
        return !Task.isCancelled
    } catch {
        return false
    }
}
