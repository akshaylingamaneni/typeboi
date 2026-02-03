import SwiftUI

struct CountingLabel: View {
    let value: Int
    var format: String = "%d"

    @State private var displayValue: Int = 0

    var body: some View {
        Text(String(format: format, displayValue))
            .fontDesign(.rounded)
            .contentTransition(.numericText(value: Double(displayValue)))
            .onChange(of: value, initial: true) { _, newValue in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    displayValue = newValue
                }
            }
    }
}

struct AnimatedWPM: View {
    let wpm: Double
    @State private var displayWPM: Double = 0

    var body: some View {
        Text(displayWPM > 0 ? String(format: "%.0f", displayWPM) : "–")
            .fontDesign(.rounded)
            .contentTransition(.numericText(value: displayWPM))
            .onChange(of: wpm, initial: true) { _, newValue in
                withAnimation(.easeOut(duration: 0.3)) {
                    displayWPM = newValue
                }
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        CountingLabel(value: 12345)
            .font(.largeTitle)
            .fontWeight(.bold)

        AnimatedWPM(wpm: 65.5)
            .font(.title)
            .fontWeight(.semibold)
    }
    .padding()
}
