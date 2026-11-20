import SwiftUI

struct SetupView: View {
    @Environment(StatusMenuViewStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Form {
            Section("Work schedule") {
                LabeledContent("Days") {
                    SetupDaysView(days: days)
                }
                LabeledContent("Hours") {
                    HStack {
                        DatePicker("From", selection: start, displayedComponents: .hourAndMinute)
                        Text("to")
                        DatePicker("To", selection: end, displayedComponents: .hourAndMinute)
                    }
                    .labelsHidden()
                }
            }
            Section {
                Toggle("Launch at login", isOn: $store.launchesAtLogin)
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var days: Binding<Set<Int>> {
        Binding(get: { store.workHours.days }, set: { change(days: $0) })
    }

    private var start: Binding<Date> {
        Binding(get: { date(at: store.workHours.startMinute) }, set: { change(startMinute: minute(of: $0)) })
    }

    private var end: Binding<Date> {
        Binding(get: { date(at: store.workHours.endMinute) }, set: { change(endMinute: minute(of: $0)) })
    }

    private func date(at minute: Int) -> Date {
        Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: .now) ?? .now
    }

    private func minute(of date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    private func change(days: Set<Int>? = nil, startMinute: Int? = nil, endMinute: Int? = nil) {
        let hours = store.workHours
        if let changed = WorkHours(
            days: days ?? hours.days,
            startMinute: startMinute ?? hours.startMinute,
            endMinute: endMinute ?? hours.endMinute) {
            store.workHours = changed
        }
    }
}

#Preview {
    SetupView()
        .environment(StatusMenuViewStore.preview)
}
