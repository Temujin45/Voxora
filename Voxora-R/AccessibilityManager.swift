import AppKit
import ApplicationServices

final class AccessibilityManager {

    static let shared = AccessibilityManager()

    private init() {}

    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func requestPermission() {

        let options = [
            kAXTrustedCheckOptionPrompt.takeRetainedValue()
                as String: true
        ] as CFDictionary

        _ = AXIsProcessTrustedWithOptions(
            options
        )
    }
}
