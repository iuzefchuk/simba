import SwiftUI

struct MarkView: View {
    var size: CGFloat

    var body: some View {
        Image(.mark)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

#Preview {
    MarkView(size: 64)
        .padding()
}
