import Foundation

enum FileManagerAppFolder {
    static var applicationSupport: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appending(path: ProcessInfo.processInfo.processName)
    }

    static func temporary(_ purpose: String) -> URL {
        FileManager.default.temporaryDirectory.appending(path: "\(ProcessInfo.processInfo.processName)\(purpose)")
    }

    static func empty(_ folder: URL) throws {
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }
}
