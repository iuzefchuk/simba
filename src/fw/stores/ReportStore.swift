import Foundation
import Observation

@MainActor
@Observable
final class ReportStore {
    private(set) var reports: [Report] = []
    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private var canSave = true

    init(fileURL: URL) {
        self.fileURL = fileURL
        do {
            reports = try JSONStorage.load(ReportFile.self, from: fileURL)?.reports ?? []
        } catch {
            NSLogDiagnostics.note("failed to read reports: \(error)")
            do {
                let backup = try JSONStorage.moveAside(fileURL)
                NSLogDiagnostics.note("moved the unreadable reports to \(backup.path(percentEncoded: false))")
            } catch {
                NSLogDiagnostics.note("failed to move the unreadable reports aside, so nothing will be saved: \(error)")
                canSave = false
            }
        }
    }

    var openReport: Report? { reports.openReport }
    var latestReport: Report? { reports.last }

    @discardableResult
    func startReport(at date: Date = .now) -> Report? {
        apply { try reports.start(at: date) }
    }

    @discardableResult
    func endReport() -> Report? {
        apply { try reports.end(at: .now) }
    }

    func endStaleReport() {
        if reports.endStale(now: .now) != nil { save() }
    }

    @discardableResult
    func add(_ entry: Entry) -> Report? {
        apply { try reports.add(entry) }
    }

    @discardableResult
    func remove(_ entryID: Entry.ID, from reportID: Report.ID) -> Report? {
        apply { try reports.remove(entryID, from: reportID) }
    }

    nonisolated static var defaultFileURL: URL {
        FileManagerAppFolder.applicationSupport.appending(path: "reports.json")
    }

    private func apply(_ change: () throws -> Report) -> Report? {
        do {
            let report = try change()
            save()
            return report
        } catch {
            NSLogDiagnostics.note("the change was rejected: \(error)")
            return nil
        }
    }

    private func save() {
        guard canSave else { return }
        do {
            try JSONStorage.save(ReportFile(reports: reports), to: fileURL)
        } catch {
            NSLogDiagnostics.note("failed to save reports: \(error)")
        }
    }
}

private struct ReportFile: Codable {
    static let version = 1

    let reports: [Report]

    private enum CodingKeys: String, CodingKey {
        case version
        case reports
    }

    init(reports: [Report]) {
        self.reports = reports
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        guard version == Self.version else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: container, debugDescription: "the reports file is version \(version), not \(Self.version)")
        }
        reports = try container.decode([StoredReport].self, forKey: .reports).map(\.report)
        if let violation = reports.violation {
            throw DecodingError.dataCorruptedError(forKey: .reports, in: container, debugDescription: "the reports violate \(violation)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.version, forKey: .version)
        try container.encode(reports.map(StoredReport.init), forKey: .reports)
    }
}

private struct StoredReport: Codable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date?
    let entries: [StoredEntry]

    init(_ report: Report) {
        id = report.id
        startedAt = report.startedAt
        endedAt = report.endedAt
        entries = report.entries.map(StoredEntry.init)
    }

    var report: Report {
        Report(stored: id, startedAt: startedAt, endedAt: endedAt, entries: entries.map(\.entry))
    }
}

private struct StoredEntry: Codable {
    let id: UUID
    let date: Date
    let text: String

    init(_ entry: Entry) {
        id = entry.id
        date = entry.date
        text = entry.text
    }

    var entry: Entry {
        Entry(stored: id, date: date, text: text)
    }
}
