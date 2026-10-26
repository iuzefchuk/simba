import Foundation

struct Entry: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let text: String

    init?(id: UUID = UUID(), date: Date, text: String) {
        guard let text = Self.normalized(text) else { return nil }
        self.id = id
        self.date = date
        self.text = text
    }

    init(stored id: UUID, date: Date, text: String) {
        self.id = id
        self.date = date
        self.text = text
    }

    var isNormalized: Bool { Self.normalized(text) == text }

    static func normalized(_ text: String) -> String? {
        let words = text.split(whereSeparator: \.isWhitespace)
        return words.isEmpty ? nil : words.joined(separator: " ")
    }
}
