import SwiftUI

struct SetupView: View {
    @Environment(StatusMenuViewStore.self) private var store

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                MarkView(size: 64)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Simba")
                        .font(.title.weight(.semibold))
                    Text("Hourly entries during your work hours.")
                        .foregroundStyle(.secondary)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Text("Days")
                        .foregroundStyle(.secondary)
                    SetupDaysView(days: days)
                }
                GridRow {
                    Text("Hours")
                        .foregroundStyle(.secondary)
                    HStack {
                        DatePicker("From", selection: start, displayedComponents: .hourAndMinute)
                        Text("to")
                        DatePicker("To", selection: end, displayedComponents: .hourAndMinute)
                    }
                    .labelsHidden()
                }
            }

            Text("Simba starts logging when your work hours begin and asks what you're doing every hour. When they end, every answer appears in one list you can copy.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle("Launch at Login, so Simba is running when work starts", isOn: $store.launchesAtLogin)
                .toggleStyle(.checkbox)
        }
        .padding(24)
        .frame(width: 480)
        .background(Color(.ivory))
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
