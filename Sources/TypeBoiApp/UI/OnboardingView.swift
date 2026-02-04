import SwiftUI

struct OnboardingView: View {
    @ObservedObject var accessibility: AccessibilityMonitor
    let onComplete: () -> Void

    @State private var currentPage = 0
    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            pageContent
            Spacer(minLength: Spacing.md)
            pageIndicator
            navigationButtons
        }
        .padding(Spacing.lg)
        .frame(width: 360, height: 480)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case 0: welcomePage
        case 1: featuresPage
        case 2: privacyPage
        default: welcomePage
        }
    }

    private var welcomePage: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.gradient)
                    .frame(width: 88, height: 88)
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            VStack(spacing: Spacing.sm) {
                Text("Welcome to TypeBoi")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Track your typing stats, measure your speed, and see how you use your keyboard across apps.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.horizontal, Spacing.md)

            Spacer()
        }
    }

    private var featuresPage: some View {
        VStack(spacing: Spacing.lg) {
            Text("Features")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: Spacing.md) {
                OnboardingFeatureRow(
                    icon: "speedometer",
                    color: .blue,
                    title: "Live WPM",
                    description: "Real-time words per minute"
                )
                OnboardingFeatureRow(
                    icon: "chart.bar.fill",
                    color: .green,
                    title: "Daily Stats",
                    description: "Keystrokes, backspaces, shortcuts"
                )
                OnboardingFeatureRow(
                    icon: "calendar",
                    color: .orange,
                    title: "History",
                    description: "GitHub-style activity heatmap"
                )
                OnboardingFeatureRow(
                    icon: "square.grid.2x2.fill",
                    color: .purple,
                    title: "Per-App Stats",
                    description: "See where you type most"
                )
            }
            .padding(.horizontal, Spacing.sm)

            Spacer()
        }
    }

    private var privacyPage: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.green.gradient)
                    .frame(width: 64, height: 64)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }

            Text("Your Privacy")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                OnboardingPrivacyRow(icon: "checkmark.circle.fill", text: "Counts only — never logs keys")
                OnboardingPrivacyRow(icon: "checkmark.circle.fill", text: "No passwords or text stored")
                OnboardingPrivacyRow(icon: "checkmark.circle.fill", text: "Data stays on your Mac")
                OnboardingPrivacyRow(icon: "checkmark.circle.fill", text: "No cloud or analytics")
            }
            .padding(Spacing.md)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)

            VStack(spacing: Spacing.xs) {
                Text("Accessibility Permission")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Required to count keystrokes system-wide.\nWe only count — never read content.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: i == currentPage ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
        .padding(.bottom, Spacing.md)
    }

    private var navigationButtons: some View {
        HStack {
            if currentPage > 0 {
                Button("Back") {
                    withAnimation(.spring(response: 0.3)) { currentPage -= 1 }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            } else {
                Spacer().frame(width: 50)
            }

            Spacer()

            if currentPage < totalPages - 1 {
                Button {
                    withAnimation(.spring(response: 0.3)) { currentPage += 1 }
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(width: 100)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button {
                    requestPermissionAndComplete()
                } label: {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(width: 110)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private func requestPermissionAndComplete() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        accessibility.refresh()
        onComplete()
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.gradient)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

struct OnboardingPrivacyRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(accessibility: AccessibilityMonitor()) {}
}
