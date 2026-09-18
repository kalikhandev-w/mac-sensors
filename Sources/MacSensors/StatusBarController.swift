import AppKit
import MacSensorsCore
import SwiftUI

@Observable
final class PanelModel {
    var snapshot = Snapshot()
}

/// Owns the status item and popover. The refresh timer exists only while the popover is shown.
final class StatusBarController: NSObject, NSPopoverDelegate {
    private static let refreshInterval: TimeInterval = 2
    /// First CPU-load sample needs two tick readings; take the second one quickly.
    private static let firstLoadDelay: TimeInterval = 0.5

    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let provider = SensorProvider()
    private let model = PanelModel()
    private var timer: Timer?
    private var outsideClickMonitor: Any?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        let image = NSImage(systemSymbolName: "thermometer.medium", accessibilityDescription: "MacSensors")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        popover.behavior = .transient
        popover.delegate = self
        let host = NSHostingController(rootView: PanelView(model: model, quit: { NSApp.terminate(nil) }))
        // Without this the popover opens at a default size, then shrinks and drifts away from the anchor.
        host.sizingOptions = .preferredContentSize
        popover.contentViewController = host
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func popoverWillShow(_ notification: Notification) {
        refresh()
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.firstLoadDelay) { [weak self] in
            guard let self, self.popover.isShown else { return }
            self.refresh()
        }
        let t = Timer(timeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        // .transient alone does not close the popover for a never-active accessory app,
        // so watch for clicks in other apps while shown. Removed on close.
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            self?.popover.performClose(nil)
        }
    }

    func popoverDidClose(_ notification: Notification) {
        timer?.invalidate()
        timer = nil
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }

    private func refresh() {
        model.snapshot = provider.sample()
    }
}
