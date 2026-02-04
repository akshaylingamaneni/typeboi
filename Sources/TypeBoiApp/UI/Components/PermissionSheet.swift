import SwiftUI
import AppKit

struct PermissionSheet: View {
    @ObservedObject var accessibility: AccessibilityMonitor
    var onPermissionGranted: (() -> Void)?
    @State private var isPolling = false
    @State private var showSuccess = false
    @State private var showRestartHint = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if showSuccess {
                successOverlay
            } else {
                permissionRequestView
            }
        }
        .frame(width: 320, height: 420)
        .onAppear {
            startPolling()
        }
        .onDisappear {
            isPolling = false
        }
    }

    private var permissionRequestView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, options: .repeating, isActive: isPolling)

            VStack(spacing: Spacing.sm) {
                Text("Accessibility Permission")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("TypeBoi needs accessibility access to count your keystrokes. Your typing data stays on your device.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Spacing.md) {
                Button(action: openSystemSettings) {
                    Label("Open System Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Check Again") {
                    checkPermission()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }

            if showRestartHint {
                VStack(spacing: Spacing.sm) {
                    Text("Already enabled? Restart may be required.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Continue Anyway") {
                        dismiss()
                    }
                    .font(.caption)
                }
                .transition(.opacity)
            }

            if isPolling && !showRestartHint {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Waiting for permission...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(Spacing.xl)
    }

    private var successOverlay: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: showSuccess)

            Text("Permission Granted!")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Tracking is now active")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    private func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        startPolling()
    }

    private func checkPermission() {
        accessibility.refresh()
        if accessibility.isTrusted {
            handleSuccess()
        } else {
            withAnimation {
                showRestartHint = true
            }
        }
    }

    private func startPolling() {
        isPolling = true
        Task {
            var pollCount = 0
            while isPolling && !accessibility.isTrusted {
                try? await Task.sleep(for: .seconds(1))
                pollCount += 1
                await MainActor.run {
                    accessibility.refresh()
                    if accessibility.isTrusted {
                        handleSuccess()
                    } else if pollCount >= 5 {
                        withAnimation {
                            showRestartHint = true
                        }
                    }
                }
            }
        }
    }

    private func handleSuccess() {
        isPolling = false
        withAnimation(.spring(response: 0.4)) {
            showSuccess = true
        }
        onPermissionGranted?()
        NotificationCenter.default.post(name: .accessibilityPermissionGranted, object: nil)
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                dismiss()
            }
        }
    }
}

extension Notification.Name {
    static let accessibilityPermissionGranted = Notification.Name("accessibilityPermissionGranted")
}

#Preview {
    PermissionSheet(accessibility: AccessibilityMonitor())
}
