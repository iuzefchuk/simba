import Foundation

struct Entry: Identifiable, Equatable, Codable {
    let id: UUID
    let date: Date
    let text: String

    init?(date: Date, text: String) {
        guard let text = Self.normalized(text) else { return nil }
        id = UUID()
        self.date = date
        self.text = text
    }

    var isNormalized: Bool { Self.normalized(text) == text }

    static func normalized(_ text: String) -> String? {
        let words = text.split(whereSeparator: \.isWhitespace)
        return words.isEmpty ? nil : words.joined(separator: " ")
    }
}
