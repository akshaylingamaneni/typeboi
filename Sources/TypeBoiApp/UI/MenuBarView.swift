import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var statsEngine: StatsEngine
    @ObservedObject var settings: AppSettings
    @ObservedObject var accessibility: AccessibilityMonitor
    let statsStore: StatsStore

    @State private var selectedTab = 0
    @State private var showPermissionSheet = false
    @State private var showResetConfirm = false
    @State private var showExportSuccess = false
    @State private var showResetSuccess = false
    @State private var exportError: String?

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider().opacity(0.5)
            tabContent
        }
        .padding(Spacing.md)
        .frame(minWidth: 360, minHeight: 520)
        .sheet(isPresented: $showPermissionSheet) {
            PermissionSheet(accessibility: accessibility)
        }
        .onAppear {
            if !accessibility.isTrusted {
                showPermissionSheet = true
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: Spacing.sm) {
            TabButton("Today", icon: "keyboard", tag: 0, selection: $selectedTab)
            TabButton("History", icon: "calendar", tag: 1, selection: $selectedTab)
            TabButton("Apps", icon: "square.grid.2x2", tag: 2, selection: $selectedTab)
            TabButton("Settings", icon: "gear", tag: 3, selection: $selectedTab)
        }
        .padding(.bottom, Spacing.sm)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0: todayView
        case 1: HistoryView(store: statsStore)
        case 2: appsView
        case 3: settingsView
        default: todayView
        }
    }

    private var todayView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                header
                statsGrid
                hourlySection
                Spacer(minLength: Spacing.md)
                actionButtons
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TypeBoi")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            wpmBadge
        }
    }

    private var dateString: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var wpmBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            AnimatedWPM(wpm: statsEngine.displayedWPM)
                .font(.title)
                .fontWeight(.bold)
            Text("WPM")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .glassCard()
    }

    private var statsGrid: some View {
        let global = statsEngine.stats.global
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
            StatCard("Keystrokes", value: formatted(global.keystrokesTotal), icon: "keyboard")
            StatCard("Printable", value: formatted(global.keystrokesPrintable), icon: "character")
            StatCard("Backspace", value: formatted(global.backspaceCount), icon: "delete.left")
            StatCard("Shortcuts", value: formatted(global.shortcutCount), icon: "command")
            StatCard("Active", value: "\(Int(global.activeSeconds / 60))m", icon: "clock")
            StatCard("Daily WPM", value: global.wpmActive > 0 ? String(format: "%.0f", global.wpmActive) : "–", icon: "speedometer")
        }
    }

    private func formatted(_ value: Int) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", Double(value) / 1000)
        }
        return "\(value)"
    }

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Today's Activity")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HourlyChart(hourly: statsEngine.stats.hourlyGlobal)
                .frame(height: 120)
                .glassCard()
        }
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: exportYear) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)

            Button(role: .destructive, action: { showResetConfirm = true }) {
                Label("Reset", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .confirmationDialog("Reset all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset Everything", role: .destructive) { resetData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your typing statistics. This cannot be undone.")
            }

            Spacer()
            statusIndicator
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if let error = exportError {
            Label(error, systemImage: "xmark.circle")
                .font(.caption)
                .foregroundStyle(.red)
        } else if showExportSuccess {
            Label("Exported", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.green)
                .transition(.opacity)
        } else if showResetSuccess {
            Label("Reset", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.green)
                .transition(.opacity)
        }
    }

    private var appsView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Per-App Activity")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if statsEngine.stats.apps.isEmpty {
                emptyAppsState
            } else {
                appsList
            }
        }
    }

    private var emptyAppsState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "app.dashed")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No app data yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var appsList: some View {
        let sortedApps = statsEngine.stats.apps.values.sorted { $0.keystrokesTotal > $1.keystrokesTotal }
        return ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(sortedApps, id: \.appName) { app in
                    AppRow(app: app)
                }
            }
            .padding(.trailing, Spacing.sm)
        }
    }

    private var settingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                appearanceSettings
                trackingSettings
                excludedAppsSection
            }
            .padding(.top, Spacing.sm)
        }
    }

    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Appearance")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Menu Bar")
                        Text(menuBarStyleDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $settings.menuBarStyle) {
                        ForEach(MenuBarStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }
            }
            .glassCard()
        }
    }

    private var menuBarStyleDescription: String {
        switch settings.menuBarStyle {
        case .text: return "Shows \"TypeBoi\""
        case .icon: return "Keyboard icon"
        case .activity: return "Pulses when typing"
        case .wpm: return "Live WPM counter"
        }
    }

    private var trackingSettings: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Tracking")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.sm) {
                settingRow("Idle Threshold", value: "\(Int(settings.idleThreshold))s") {
                    Stepper("", value: $settings.idleThreshold, in: 10...120, step: 5)
                        .labelsHidden()
                }

                settingRow("Burst Gap", value: String(format: "%.1fs", settings.burstGap)) {
                    Stepper("", value: $settings.burstGap, in: 1...5, step: 0.5)
                        .labelsHidden()
                }
            }
            .glassCard()
        }
    }

    private func settingRow<Content: View>(_ label: String, value: String, @ViewBuilder control: () -> Content) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            control()
        }
    }

    private var excludedAppsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Excluded Apps")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            ExcludedAppsView(settings: settings)
                .frame(maxHeight: 180)
        }
    }

    private func exportYear() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "typeboi-year.json"
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try statsStore.exportYearJSON(to: url)
                exportError = nil
                withAnimation { showExportSuccess = true }
                showResetSuccess = false
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    await MainActor.run {
                        withAnimation { showExportSuccess = false }
                    }
                }
            } catch {
                exportError = "Export failed"
            }
        }
    }

    private func resetData() {
        do {
            try statsStore.resetAllData()
            statsEngine.refresh()
            exportError = nil
            withAnimation { showResetSuccess = true }
            showExportSuccess = false
            Task {
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    withAnimation { showResetSuccess = false }
                }
            }
        } catch {
            exportError = "Reset failed"
        }
    }
}

struct TabButton: View {
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
            selection = tag
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .primary : .tertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

struct AppRow: View {
    let app: AppStats
    @State private var isHovered = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(app.keystrokesTotal) keys · \(app.shortcutCount) shortcuts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatted(app.keystrokesTotal))
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
        }
        .padding(Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.primary.opacity(0.05) : .clear)
        }
        .onHover { isHovered = $0 }
    }

    private func formatted(_ value: Int) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", Double(value) / 1000)
        }
        return "\(value)"
    }
}

struct ExcludedAppsView: View {
    @ObservedObject var settings: AppSettings

    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.bundleIdentifier != nil && $0.activationPolicy != .prohibited }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(runningApps, id: \.processIdentifier) { app in
                    if let bundleID = app.bundleIdentifier {
                        HStack {
                            Text(app.localizedName ?? bundleID)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { !settings.excludedBundleIDs.contains(bundleID) },
                                set: { isIncluded in
                                    if isIncluded {
                                        settings.excludedBundleIDs.remove(bundleID)
                                    } else {
                                        settings.excludedBundleIDs.insert(bundleID)
                                    }
                                }
                            ))
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .labelsHidden()
                        }
                    }
                }
            }
            .padding(.trailing, Spacing.sm)
        }
    }
}

#Preview {
    MenuBarView(
        statsEngine: StatsEngine(store: StatsStore(), settings: AppSettings()),
        settings: AppSettings(),
        accessibility: AccessibilityMonitor(),
        statsStore: StatsStore()
    )
}
