import Foundation

struct Report: Identifiable, Equatable, Codable {
    enum Rejection: Error {
        case entryBeforeStart
        case duplicateEntry
        case noSuchEntry
        case skipBeforeStart
        case alreadyOpen
        case overlapsPrevious
        case noOpenReport
        case noSuchReport
    }

    enum Violation {
        case malformedEntry
        case duplicateEntry
        case entriesOutOfOrder
        case entryBeforeStart
        case skipsOutOfOrder
        case skipBeforeStart
        case endedBeforeLastActivity
        case duplicateReport
        case openReportNotLast
        case reportsOutOfOrder
        case reportsOverlap
    }

    static let staleAfter: TimeInterval = 16 * 3600
    static let schemaVersion = 1

    let id: UUID
    let startedAt: Date
    private(set) var endedAt: Date?
    private(set) var entries: [Entry] = []
    private(set) var skips: [Date] = []

    private enum CodingKeys: String, CodingKey {
        case id
        case startedAt
        case endedAt
        case entries
        case skips
    }

    init(startedAt: Date) {
        id = UUID()
        self.startedAt = startedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
        entries = try container.decode([Entry].self, forKey: .entries)
        skips = try container.decodeIfPresent([Date].self, forKey: .skips) ?? []
    }

    var isOpen: Bool { endedAt == nil }

    var lastActivityAt: Date { max(entries.last?.date ?? startedAt, skips.last ?? startedAt) }

    func isStale(now: Date) -> Bool {
        isOpen && now.timeIntervalSince(lastActivityAt) > Self.staleAfter
    }

    var violation: Violation? {
        if !entries.allSatisfy(\.isNormalized) { return .malformedEntry }
        if Set(entries.map(\.id)).count != entries.count { return .duplicateEntry }
        if !zip(entries, entries.dropFirst()).allSatisfy({ $0.date <= $1.date }) { return .entriesOutOfOrder }
        if let first = entries.first, first.date < startedAt { return .entryBeforeStart }
        if !zip(skips, skips.dropFirst()).allSatisfy({ $0 <= $1 }) { return .skipsOutOfOrder }
        if let first = skips.first, first < startedAt { return .skipBeforeStart }
        if let endedAt, endedAt < lastActivityAt { return .endedBeforeLastActivity }
        return nil
    }

    mutating func end(at date: Date) {
        endedAt = max(date, lastActivityAt)
    }

    mutating func endAtLastActivity() {
        endedAt = lastActivityAt
    }

    mutating func add(_ entry: Entry) throws {
        guard entry.date >= startedAt else { throw Rejection.entryBeforeStart }
        guard !entries.contains(where: { $0.id == entry.id }) else { throw Rejection.duplicateEntry }
        let index = entries.firstIndex { $0.date > entry.date } ?? entries.endIndex
        entries.insert(entry, at: index)
    }

    mutating func skip(at date: Date) throws {
        guard date >= startedAt else { throw Rejection.skipBeforeStart }
        let index = skips.firstIndex { $0 > date } ?? skips.endIndex
        skips.insert(date, at: index)
    }

    mutating func remove(_ entryID: Entry.ID) throws {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { throw Rejection.noSuchEntry }
        entries.remove(at: index)
    }
}
