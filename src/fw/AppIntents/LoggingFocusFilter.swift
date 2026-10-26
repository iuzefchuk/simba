import AppIntents

struct LoggingFocusFilter: SetFocusFilterIntent {
    static let title: LocalizedStringResource = "Hourly Entries"
    static let description: IntentDescription? = IntentDescription(
        "Asks what you're doing every hour while this Focus is on, then collects the answers into a report when it ends."
    )

    @Parameter(title: "Hourly entries", default: false)
    var isEnabled: Bool

    @Dependency private var model: AppModel

    var displayRepresentation: DisplayRepresentation {
        let subtitle: LocalizedStringResource = isEnabled ? "On" : "Off"
        return DisplayRepresentation(title: "Hourly Entries", subtitle: subtitle)
    }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            if isEnabled {
                model.startLogging()
            } else {
                model.endLogging()
            }
        }
        return .result()
    }
}
