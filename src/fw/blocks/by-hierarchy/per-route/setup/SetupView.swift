import AppKit
import SwiftUI

struct SetupView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                MarkView(size: 64)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Simba")
                        .font(.title.weight(.semibold))
                    Text("Hourly entries while your Work Focus is on.")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                SetupViewStep(number: 1, text: "Open System Settings → Focus → Work.")
                SetupViewStep(number: 2, text: "Under Focus Filters, click Add Filter, choose Simba, turn on Hourly entries, then click Add.")
                SetupViewStep(number: 3, text: "Keep Simba running: turn on Launch at Login below.")
            }

            Text("Every hour Simba asks what you're doing. When the Focus ends, every answer appears in one list you can copy.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Toggle("Launch at Login", isOn: $model.launchesAtLogin)
                    .toggleStyle(.checkbox)
                Spacer()
                Button("Open Focus Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Focus-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(.accent))
            }
        }
        .padding(24)
        .frame(width: 480)
        .background(Color(.windowBackground))
    }
}

#Preview {
    SetupView()
        .environment(AppModel.preview)
}
