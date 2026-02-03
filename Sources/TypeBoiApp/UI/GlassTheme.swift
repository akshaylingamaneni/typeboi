import SwiftUI

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(Spacing.md)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
    }

    func glassCard() -> some View {
        self.cardStyle()
    }
}

struct HeatmapIntensity {
    static func color(for intensity: Double) -> Color {
        switch intensity {
        case 0:
            return Color.secondary.opacity(0.15)
        case 0..<0.25:
            return Color.accentColor.opacity(0.4)
        case 0.25..<0.5:
            return Color.accentColor.opacity(0.6)
        case 0.5..<0.75:
            return Color.accentColor.opacity(0.8)
        default:
            return Color.accentColor
        }
    }
}
