import AppKit

final class GlobalHotkeyManager {

    private var monitor: Any?

    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private var isPressed = false

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.flagsChanged]
        ) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let optionPressed = event.modifierFlags.contains(.option)

        if optionPressed && !isPressed {
            isPressed = true
            onKeyDown?()
        } else if !optionPressed && isPressed {
            isPressed = false
            onKeyUp?()
        }
    }

    deinit {
        stop()
    }
}
