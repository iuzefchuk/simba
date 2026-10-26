import SwiftUI

struct SetupViewStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color(.accent), in: Circle())
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    SetupViewStep(number: 1, text: "Open System Settings → Focus → Work.")
        .padding()
}
