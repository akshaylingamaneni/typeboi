import SwiftUI

struct StatRow: View {
    let label: String
    let value: String
    var icon: String?

    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
            }
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    var icon: String?

    init(_ title: String, value: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .fontDesign(.rounded)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        StatRow(label: "Keystrokes", value: "12,345", icon: "keyboard")
        StatRow(label: "WPM", value: "65.2")

        HStack(spacing: Spacing.sm) {
            StatCard("Total", value: "12,345", subtitle: "keystrokes", icon: "keyboard")
            StatCard("WPM", value: "65", subtitle: "active", icon: "speedometer")
        }
    }
    .padding()
    .frame(width: 340)
}
