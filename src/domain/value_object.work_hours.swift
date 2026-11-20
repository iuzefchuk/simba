import Foundation

struct WorkHours: Equatable, Codable {
    static let standard = WorkHours(days: [2, 3, 4, 5, 6], startMinute: 9 * 60, endMinute: 18 * 60)!
    static let schemaVersion = 1

    let days: Set<Int>
    let startMinute: Int
    let endMinute: Int

    private enum CodingKeys: String, CodingKey {
        case days
        case startMinute
        case endMinute
    }

    init?(days: Set<Int>, startMinute: Int, endMinute: Int) {
        guard days.allSatisfy((1...7).contains), 0 <= startMinute, startMinute < endMinute, endMinute < 24 * 60 else { return nil }
        self.days = days
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let days = try container.decode([Int].self, forKey: .days)
        let startMinute = try container.decode(Int.self, forKey: .startMinute)
        let endMinute = try container.decode(Int.self, forKey: .endMinute)
        guard let hours = WorkHours(days: Set(days), startMinute: startMinute, endMinute: endMinute) else {
            throw DecodingError.dataCorruptedError(forKey: .days, in: container, debugDescription: "the work hours break their own rules")
        }
        self = hours
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(days.sorted(), forKey: .days)
        try container.encode(startMinute, forKey: .startMinute)
        try container.encode(endMinute, forKey: .endMinute)
    }

    func period(containing date: Date, in calendar: Calendar) -> DateInterval? {
        periods(near: date, in: calendar).first { $0.start <= date && date < $0.end }
    }

    func lastEnd(atOrBefore date: Date, in calendar: Calendar) -> Date? {
        periods(near: date, in: calendar).map(\.end).filter { $0 <= date }.max()
    }

    func nextChange(after date: Date, in calendar: Calendar) -> Date? {
        periods(near: date, in: calendar).flatMap { [$0.start, $0.end] }.filter { $0 > date }.min()
    }

    private func periods(near date: Date, in calendar: Calendar) -> [DateInterval] {
        (-7...7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: date).flatMap { period(onDayOf: $0, in: calendar) }
        }
    }

    private func period(onDayOf date: Date, in calendar: Calendar) -> DateInterval? {
        guard days.contains(calendar.component(.weekday, from: date)),
              let start = calendar.date(bySettingHour: startMinute / 60, minute: startMinute % 60, second: 0, of: date),
              let end = calendar.date(bySettingHour: endMinute / 60, minute: endMinute % 60, second: 0, of: date),
              start < end else { return nil }
        return DateInterval(start: start, end: end)
    }
}
