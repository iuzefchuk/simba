import SwiftUI

struct SetupDaysView: View {
    @Binding var days: Set<Int>

    private var orderedDays: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(orderedDays, id: \.self) { day in
                Toggle(isOn: isOn(day)) {
                    Text(Calendar.current.shortWeekdaySymbols[day - 1])
                        .frame(minWidth: 30)
                }
                .toggleStyle(.button)
            }
        }
    }

    private func isOn(_ day: Int) -> Binding<Bool> {
        Binding(
            get: { days.contains(day) },
            set: { isOn in
                if isOn { days.insert(day) } else { days.remove(day) }
            })
    }
}

#Preview {
    SetupDaysView(days: .constant(StatusMenuViewStore.preview.workHours.days))
        .padding()
}
