import SwiftUI

struct HourlyChart: View {
    let hourly: [Int: HourlyStats]
    @State private var hoveredHour: Int?

    private var maxValue: Int {
        max(hourly.values.map(\.keystrokesTotal).max() ?? 1, 1)
    }

    private func dataPoints(in size: CGSize) -> [CGPoint] {
        guard size.width > 0 else { return [] }
        let stepX = size.width / 23
        let topPadding: CGFloat = 8
        let usableHeight = size.height - topPadding
        return (0..<24).map { hour in
            let value = hourly[hour]?.keystrokesTotal ?? 0
            let x = CGFloat(hour) * stepX
            let y = topPadding + usableHeight - (CGFloat(value) / CGFloat(maxValue) * usableHeight)
            return CGPoint(x: x, y: y)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            hoverInfo

            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    lineChart(size: geo.size)
                    hoverOverlay(size: geo.size)
                }
            }
            .frame(height: 70)

            timeLabels
        }
    }

    @ViewBuilder
    private var hoverInfo: some View {
        if let hour = hoveredHour {
            let value = hourly[hour]?.keystrokesTotal ?? 0
            Text("\(hourFormatted(hour)) • \(value) keystrokes")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text(" ")
                .font(.caption)
        }
    }

    private func lineChart(size: CGSize) -> some View {
        let points = dataPoints(in: size)
        return Canvas { context, size in
            guard points.count == 24 else { return }

            let fillPath = Path { path in
                path.move(to: CGPoint(x: 0, y: size.height))
                for point in points {
                    path.addLine(to: point)
                }
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.closeSubpath()
            }

            let gradient = Gradient(colors: [
                Color.accentColor.opacity(0.3),
                Color.accentColor.opacity(0.05)
            ])
            context.fill(
                fillPath,
                with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
            )

            let linePath = Path { path in
                for (i, point) in points.enumerated() {
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
            }

            context.stroke(
                linePath,
                with: .color(Color.accentColor),
                lineWidth: 2
            )

            for (hour, point) in points.enumerated() {
                let value = hourly[hour]?.keystrokesTotal ?? 0
                if value > 0 {
                    let dotRect = CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)
                    context.fill(Circle().path(in: dotRect), with: .color(Color.accentColor))
                }
            }
        }
    }

    private func hoverOverlay(size: CGSize) -> some View {
        let points = dataPoints(in: size)
        return ZStack {
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let hour = Int((value.location.x / size.width) * 24)
                            hoveredHour = max(0, min(23, hour))
                        }
                        .onEnded { _ in
                            hoveredHour = nil
                        }
                )
                .onHover { hovering in
                    if !hovering { hoveredHour = nil }
                }

            if let hour = hoveredHour, hour < points.count {
                let point = points[hour]
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 10, height: 10)
                    .position(point)
            }
        }
    }

    private var timeLabels: some View {
        HStack {
            Text("12am")
            Spacer()
            Text("6am")
            Spacer()
            Text("12pm")
            Spacer()
            Text("6pm")
            Spacer()
            Text("11pm")
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }

    private func hourFormatted(_ hour: Int) -> String {
        if hour == 0 { return "12am" }
        if hour < 12 { return "\(hour)am" }
        if hour == 12 { return "12pm" }
        return "\(hour - 12)pm"
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
