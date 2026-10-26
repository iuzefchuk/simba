import Foundation

enum JSONStorage {
    static func load<T: Decodable>(_ type: T.Type, from url: URL) throws -> T? {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: Data(contentsOf: url))
    }

    static func save<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(value).write(to: url, options: .atomic)
    }

    @discardableResult
    static func moveAside(_ url: URL) throws -> URL {
        let stamp = Int(Date.now.timeIntervalSince1970)
        let name = "\(url.deletingPathExtension().lastPathComponent)-unreadable-\(stamp).\(url.pathExtension)"
        let destination = url.deletingLastPathComponent().appending(path: name)
        try FileManager.default.moveItem(at: url, to: destination)
        return destination
    }
}
