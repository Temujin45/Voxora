import AppKit
import Foundation

final class TextInserter {

    private var targetApplication: NSRunningApplication?

    // MARK: - Capture Target

    func captureTargetApplication() {

        guard let app =
                NSWorkspace.shared
                    .frontmostApplication
        else {
            return
        }

        targetApplication = app

        print(
            "VOXORA: TARGET APP \(app.localizedName ?? "Unknown")"
        )
    }

    // MARK: - Insert

    func insertText(_ text: String) {

        guard !text.isEmpty else {
            print("VOXORA: EMPTY TRANSCRIPT")
            return
        }

        guard AccessibilityManager.shared.isTrusted() else {

            print(
                "VOXORA: ACCESSIBILITY PERMISSION MISSING"
            )

            AccessibilityManager.shared.requestPermission()

            return
        }

        print("VOXORA: INSERTING TEXT")

        let pasteboard =
            NSPasteboard.general

        let previousString =
            pasteboard.string(
                forType: .string
            )

        pasteboard.clearContents()

        pasteboard.setString(
            text,
            forType: .string
        )

        // Restore the original target app only if
        // something else became active.
        if let targetApplication,
           !targetApplication.isActive {

            print(
                "VOXORA: REACTIVATING \(targetApplication.localizedName ?? "TARGET")"
            )

            targetApplication.activate()
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.20
        ) {

            self.sendCommandV()

            print(
                "VOXORA: TEXT PASTED"
            )

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.35
            ) {

                pasteboard.clearContents()

                if let previousString {

                    pasteboard.setString(
                        previousString,
                        forType: .string
                    )
                }

                print(
                    "VOXORA: CLIPBOARD RESTORED"
                )
            }
        }
    }

    // MARK: - Cmd + V

    private func sendCommandV() {

        guard let source =
                CGEventSource(
                    stateID:
                        .combinedSessionState
                )
        else {
            return
        }

        let keyDown =
            CGEvent(
                keyboardEventSource: source,
                virtualKey: 9,
                keyDown: true
            )

        let keyUp =
            CGEvent(
                keyboardEventSource: source,
                virtualKey: 9,
                keyDown: false
            )

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(
            tap: .cgSessionEventTap
        )

        keyUp?.post(
            tap: .cgSessionEventTap
        )
    }
}
