import Foundation

final class JSONStorage: StoragePort {
    private let folder: URL
    private var frozenKeys: Set<String> = []

    init(folder: URL) {
        self.folder = folder
    }

    static var applicationSupport: JSONStorage {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return JSONStorage(folder: support.appending(path: ProcessInfo.processInfo.processName))
    }

    static func temporary(_ purpose: String) -> JSONStorage {
        let folder = FileManager.default.temporaryDirectory.appending(path: "\(ProcessInfo.processInfo.processName)\(purpose)")
        try? FileManager.default.removeItem(at: folder)
        return JSONStorage(folder: folder)
    }

    func load<Value: Decodable>(_ type: Value.Type, key: String, version: Int) -> Value? {
        let file = file(for: key)
        guard FileManager.default.fileExists(atPath: file.path(percentEncoded: false)) else { return nil }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.userInfo[.envelopeKey] = key
            decoder.userInfo[.envelopeVersion] = version
            return try decoder.decode(Envelope<Value>.self, from: Data(contentsOf: file)).value
        } catch {
            NSLog("%@", "failed to read \(file.lastPathComponent): \(error)")
            setAside(key: key)
            return nil
        }
    }

    func save<Value: Encodable>(_ value: Value, key: String, version: Int) {
        guard !frozenKeys.contains(key) else { return }
        let file = file(for: key)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try encoder.encode(Envelope(key: key, version: version, value: value)).write(to: file, options: .atomic)
        } catch {
            NSLog("%@", "failed to save \(file.lastPathComponent): \(error)")
        }
    }

    func setAside(key: String) {
        let file = file(for: key)
        guard FileManager.default.fileExists(atPath: file.path(percentEncoded: false)) else { return }
        let stamp = Int(Date.now.timeIntervalSince1970)
        let destination = folder.appending(path: "\(key)-unreadable-\(stamp).json")
        do {
            try FileManager.default.moveItem(at: file, to: destination)
            NSLog("%@", "moved the unreadable \(file.lastPathComponent) to \(destination.path(percentEncoded: false))")
        } catch {
            NSLog("%@", "failed to move the unreadable \(file.lastPathComponent) aside, so it will not be saved over: \(error)")
            frozenKeys.insert(key)
        }
    }

    private func file(for key: String) -> URL {
        folder.appending(path: "\(key).json")
    }
}

private struct Envelope<Value> {
    let key: String
    let version: Int
    let value: Value
}

extension Envelope: Decodable where Value: Decodable {
    init(from decoder: Decoder) throws {
        guard let key = decoder.userInfo[.envelopeKey] as? String,
              let version = decoder.userInfo[.envelopeVersion] as? Int else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "the decoder was not told which key and version to expect"))
        }
        let container = try decoder.container(keyedBy: EnvelopeKey.self)
        let found = try container.decode(Int.self, forKey: .version)
        guard found == version else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: container, debugDescription: "the file is version \(found), not \(version)")
        }
        self.key = key
        self.version = version
        value = try container.decode(Value.self, forKey: EnvelopeKey(key))
    }
}

extension Envelope: Encodable where Value: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EnvelopeKey.self)
        try container.encode(version, forKey: .version)
        try container.encode(value, forKey: EnvelopeKey(key))
    }
}

private struct EnvelopeKey: CodingKey {
    static let version = EnvelopeKey("version")

    let stringValue: String
    var intValue: Int? { nil }

    init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        nil
    }
}

private extension CodingUserInfoKey {
    static let envelopeKey = CodingUserInfoKey(rawValue: "envelopeKey")!
    static let envelopeVersion = CodingUserInfoKey(rawValue: "envelopeVersion")!
}
