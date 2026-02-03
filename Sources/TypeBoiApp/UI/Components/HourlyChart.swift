import SwiftUI

struct HourlyChart: View {
    let hourly: [Int: HourlyStats]
    @State private var hoveredHour: Int?

    private var maxValue: Int {
        hourly.values.map(\.keystrokesTotal).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<24, id: \.self) { hour in
                    barView(for: hour)
                }
            }
            .frame(maxWidth: .infinity)

            HStack {
                Text("12am")
                Spacer()
                Text("12pm")
                Spacer()
                Text("11pm")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private func barView(for hour: Int) -> some View {
        let value = hourly[hour]?.keystrokesTotal ?? 0
        let isHovered = hoveredHour == hour

        VStack(spacing: 2) {
            if isHovered {
                Text("\(value)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .scale))
            }

            RoundedRectangle(cornerRadius: 3)
                .fill(barColor(value: value, isHovered: isHovered))
                .frame(width: 10, height: barHeight(value: value))
                .scaleEffect(isHovered ? 1.1 : 1.0, anchor: .bottom)
                .animation(.spring(response: 0.3), value: isHovered)
        }
        .frame(height: 100, alignment: .bottom)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                hoveredHour = hovering ? hour : nil
            }
        }
        .help("\(hour):00 — \(value) keystrokes")
    }

    private func barHeight(value: Int) -> CGFloat {
        guard maxValue > 0 else { return 4 }
        return max(4, CGFloat(value) / CGFloat(maxValue) * 80)
    }

    private func barColor(value: Int, isHovered: Bool) -> Color {
        if value == 0 {
            return Color.secondary.opacity(0.15)
        }
        let intensity = Double(value) / Double(maxValue)
        let baseOpacity = 0.4 + (intensity * 0.5)
        return Color.accentColor.opacity(isHovered ? min(1, baseOpacity + 0.2) : baseOpacity)
    }
}

#Preview {
    HourlyChart(hourly: [
        8: HourlyStats(keystrokesTotal: 500),
        9: HourlyStats(keystrokesTotal: 1200),
        10: HourlyStats(keystrokesTotal: 800),
        11: HourlyStats(keystrokesTotal: 1500),
        12: HourlyStats(keystrokesTotal: 200),
        14: HourlyStats(keystrokesTotal: 1800),
        15: HourlyStats(keystrokesTotal: 2000),
        16: HourlyStats(keystrokesTotal: 1600)
    ])
    .padding()
    .frame(width: 340, height: 140)
}
