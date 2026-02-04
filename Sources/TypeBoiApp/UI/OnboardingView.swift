import SwiftUI

struct OnboardingView: View {
    @ObservedObject var accessibility: AccessibilityMonitor
    let onComplete: () -> Void

    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider().opacity(0.5)

            Group {
                switch currentPage {
                case 0: welcomePage
                case 1: featuresPage
                case 2: privacyPage
                default: welcomePage
                }
            }
            .frame(maxHeight: .infinity)

            navigationButtons
        }
        .padding(Spacing.md)
        .frame(width: 360, height: 460)
    }

    private var tabBar: some View {
        HStack(spacing: Spacing.sm) {
            OnboardingTabButton("Welcome", icon: "hand.wave", tag: 0, selection: $currentPage)
            OnboardingTabButton("Features", icon: "star", tag: 1, selection: $currentPage)
            OnboardingTabButton("Privacy", icon: "lock.shield", tag: 2, selection: $currentPage)
        }
        .padding(.bottom, Spacing.sm)
    }

    private var welcomePage: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .padding(.bottom, Spacing.md)

            VStack(spacing: Spacing.sm) {
                Text("Welcome to TypeBoi")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Track your typing stats, measure your speed, and see how you use your keyboard across apps.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Spacing.md)

            Spacer()
            Spacer()
        }
    }

    private var featuresPage: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("What you get")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.top, Spacing.sm)

            VStack(alignment: .leading, spacing: Spacing.md) {
                FeatureItem(icon: "speedometer", title: "Live WPM", description: "Real-time words per minute as you type")
                FeatureItem(icon: "chart.bar", title: "Daily Stats", description: "Keystrokes, backspaces, and shortcuts tracked")
                FeatureItem(icon: "calendar", title: "History", description: "GitHub-style heatmap of your activity")
                FeatureItem(icon: "square.grid.2x2", title: "Per-App Stats", description: "See which apps you type most in")
                FeatureItem(icon: "menubar.rectangle", title: "Menu Bar", description: "Quick access from your menu bar")
            }

            Spacer()
        }
    }

    private var privacyPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Your data is safe")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top, Spacing.sm)

                VStack(alignment: .leading, spacing: Spacing.md) {
                    PrivacyItem(text: "Counts only — never logs what you type")
                    PrivacyItem(text: "No passwords or secrets stored")
                    PrivacyItem(text: "Data stays on your Mac — no cloud")
                    PrivacyItem(text: "No network, analytics, or telemetry")
                    PrivacyItem(text: "You can inspect your data anytime")
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Why Accessibility Permission?")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("macOS requires this permission to monitor keystrokes system-wide.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Text("Used by text expanders, clipboard managers, and keyboard utilities.")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                    }

                    Text("We only count key events — never capture, store, or transmit actual characters.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, Spacing.xs)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Data Location")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("~/Library/Application Support/TypeBoi/")
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Text("Plain JSON files — open them anytime to see exactly what's stored.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.lg)
            }
            .padding(.trailing, Spacing.sm)
        }
    }

    private var navigationButtons: some View {
        HStack {
            if currentPage > 0 {
                Button("Back") {
                    withAnimation { currentPage -= 1 }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if currentPage < 2 {
                Button("Next") {
                    withAnimation { currentPage += 1 }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            } else {
                Button("Get Started") {
                    requestPermissionAndComplete()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(.top, Spacing.sm)
    }

    private func requestPermissionAndComplete() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        accessibility.refresh()
        onComplete()
    }
}

struct OnboardingTabButton: View {
    let title: String
    let icon: String
    let tag: Int
    @Binding var selection: Int

    init(_ title: String, icon: String, tag: Int, selection: Binding<Int>) {
        self.title = title
        self.icon = icon
        self.tag = tag
        self._selection = selection
    }

    private var isSelected: Bool { selection == tag }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = tag
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .primary : .tertiary)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PrivacyItem: View {
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.green)
            Text(text)
                .font(.callout)
        }
    }
}

#Preview {
    OnboardingView(accessibility: AccessibilityMonitor()) {}
}
