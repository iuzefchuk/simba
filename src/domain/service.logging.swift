import Foundation

enum Logging {
    static func nextPrompt(after date: Date, in calendar: Calendar) -> Date {
        let topOfHour = DateComponents(minute: 0, second: 0)
        return calendar.nextDate(after: date, matching: topOfHour, matchingPolicy: .nextTime)
            ?? date.addingTimeInterval(3600)
    }
}

extension [Report] {
    var openReport: Report? { first(where: \.isOpen) }

    func isStartDue(during hours: WorkHours, at date: Date, in calendar: Calendar) -> Bool {
        guard openReport == nil, let period = hours.period(containing: date, in: calendar) else { return false }
        return (last?.endedAt ?? .distantPast) <= period.start
    }

    func endDue(during hours: WorkHours, at date: Date, in calendar: Calendar) -> Date? {
        guard let openReport, let end = hours.lastEnd(atOrBefore: date, in: calendar), openReport.startedAt < end else { return nil }
        return end
    }

    var violation: Report.Violation? {
        if let violation = compactMap(\.violation).first { return violation }
        if Set(map(\.id)).count != count { return .duplicateReport }
        if dropLast().contains(where: \.isOpen) { return .openReportNotLast }
        if !zip(self, dropFirst()).allSatisfy({ $0.startedAt <= $1.startedAt }) { return .reportsOutOfOrder }
        if !zip(self, dropFirst()).allSatisfy({ ($0.endedAt ?? .distantFuture) <= $1.startedAt }) { return .reportsOverlap }
        return nil
    }

    mutating func start(at date: Date) throws -> Report {
        guard openReport == nil else { throw Report.Rejection.alreadyOpen }
        if let endedAt = last?.endedAt, date < endedAt { throw Report.Rejection.overlapsPrevious }
        let report = Report(startedAt: date)
        append(report)
        return report
    }

    mutating func end(at date: Date) throws -> Report {
        try changeOpen { $0.end(at: date) }
    }

    mutating func endStale(now: Date) -> Report? {
        guard let index = firstIndex(where: \.isOpen), self[index].isStale(now: now) else { return nil }
        if self[index].entries.isEmpty { return remove(at: index) }
        self[index].endAtLastActivity()
        return self[index]
    }

    mutating func add(_ entry: Entry) throws -> Report {
        try changeOpen { try $0.add(entry) }
    }

    mutating func skip(at date: Date) throws -> Report {
        try changeOpen { try $0.skip(at: date) }
    }

    mutating func remove(_ entryID: Entry.ID, from reportID: Report.ID) throws -> Report {
        guard let index = firstIndex(where: { $0.id == reportID }) else { throw Report.Rejection.noSuchReport }
        try self[index].remove(entryID)
        return self[index]
    }

    private mutating func changeOpen(_ apply: (inout Report) throws -> Void) throws -> Report {
        guard let index = firstIndex(where: \.isOpen) else { throw Report.Rejection.noOpenReport }
        try apply(&self[index])
        return self[index]
    }
}
