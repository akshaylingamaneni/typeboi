import Cocoa
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var monitor: KeyboardMonitor!
    private var statsStore: StatsStore!
    private var statsEngine: StatsEngine!
    private var settings: AppSettings!
    private var accessibilityMonitor: AccessibilityMonitor!
    private var saveTimer: Timer?
    private var menuBarUpdateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastKeystrokeTime: Date = .distantPast

    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            await setupApp()
        }
    }

    private func setupApp() async {
        accessibilityMonitor = AccessibilityMonitor()
        settings = AppSettings()
        statsStore = StatsStore()
        statsEngine = StatsEngine(store: statsStore, settings: settings)

        monitor = KeyboardMonitor()
        monitor.onKeyEvent = { [weak self] event in
            Task { @MainActor [weak self] in
                self?.statsEngine.handle(event: event)
                self?.lastKeystrokeTime = Date()
            }
        }

        requestAccessibilityIfNeeded()
        accessibilityMonitor.refresh()

        _ = monitor.start()
        setupStatusItem()
        setupPopover()
        setupSaveTimer()
        setupMenuBarUpdates()
    }

    nonisolated func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            saveTimer?.invalidate()
            menuBarUpdateTimer?.invalidate()
            statsStore.saveIfNeeded()
            monitor.stop()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
        }
        updateMenuBarDisplay()
    }

    private func setupMenuBarUpdates() {
        settings.$menuBarStyle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarDisplay()
            }
            .store(in: &cancellables)

        menuBarUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMenuBarDisplay()
            }
        }
    }

    private func updateMenuBarDisplay() {
        guard let button = statusItem.button else { return }

        switch settings.menuBarStyle {
        case .text:
            button.image = nil
            button.title = "TypeBoi"

        case .icon:
            button.title = ""
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "TypeBoi")

        case .activity:
            button.title = ""
            let isActive = Date().timeIntervalSince(lastKeystrokeTime) < 2
            let symbolName = isActive ? "keyboard.fill" : "keyboard"
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: isActive ? .bold : .regular)
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "TypeBoi")?
                .withSymbolConfiguration(config)

        case .wpm:
            button.image = nil
            let wpm = Int(statsEngine.displayedWPM)
            button.title = wpm > 0 ? "\(wpm) wpm" : "– wpm"
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 560)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(
                statsEngine: statsEngine,
                settings: settings,
                accessibility: accessibilityMonitor,
                statsStore: statsStore
            )
        )
    }

    private func setupSaveTimer() {
        saveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.statsStore.saveIfNeeded()
            }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func requestAccessibilityIfNeeded() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
