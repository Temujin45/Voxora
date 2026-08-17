import AppKit
import SwiftUI

final class ListeningPillWindow: NSPanel {

    let model = ListeningPillModel()

    private let pillWidth: CGFloat = 150
    private let pillHeight: CGFloat = 36
    private let bottomPadding: CGFloat = 32

    init() {

        guard let screen =
                NSScreen.main ??
                NSScreen.screens.first
        else {
            super.init(
                contentRect: .zero,
                styleMask: [
                    .nonactivatingPanel,
                    .borderless
                ],
                backing: .buffered,
                defer: false
            )

            return
        }

        let screenFrame = screen.visibleFrame

        let x =
            screenFrame.midX -
            pillWidth / 2

        let y =
            screenFrame.minY +
            bottomPadding

        let frame = NSRect(
            x: x,
            y: y,
            width: pillWidth,
            height: pillHeight
        )

        super.init(
            contentRect: frame,
            styleMask: [
                .nonactivatingPanel,
                .borderless
            ],
            backing: .buffered,
            defer: false
        )

        level = .floating

        isOpaque = false

        backgroundColor = .clear

        hasShadow = false

        ignoresMouseEvents = true

        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        // Keep the pill from stealing focus.
        hidesOnDeactivate = false

        // Make sure this panel itself never becomes key/main.
        becomesKeyOnlyIfNeeded = false

        contentView = NSHostingView(
            rootView:
                ListeningPillView(
                    model: model
                )
        )
    }

    // MARK: - Show

    func showPill() {

        guard !isVisible else {
            return
        }

        print(
            "VOXORA: SHOWING LISTENING PILL"
        )

        // Reposition in case the active screen changed.
        positionPill()

        orderFrontRegardless()
    }

    // MARK: - Hide

    func hidePill() {

        guard isVisible else {
            return
        }

        print(
            "VOXORA: HIDING LISTENING PILL"
        )

        orderOut(nil)

        model.setAudioLevel(0)
    }

    // MARK: - Audio Level

    func updateAudioLevel(
        _ level: Float
    ) {

        model.setAudioLevel(level)
    }

    // MARK: - Position

    private func positionPill() {

        guard let screen =
                NSScreen.main ??
                NSScreen.screens.first
        else {
            return
        }

        let screenFrame =
            screen.visibleFrame

        let x =
            screenFrame.midX -
            pillWidth / 2

        let y =
            screenFrame.minY +
            bottomPadding

        setFrameOrigin(
            NSPoint(
                x: x,
                y: y
            )
        )
    }
}
