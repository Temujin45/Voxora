import SwiftUI
import Combine

@MainActor
final class ListeningPillModel: ObservableObject {

    @Published var audioLevel: Float = 0

    func setAudioLevel(_ level: Float) {
        audioLevel = level
    }
}

struct ListeningPillView: View {

    @ObservedObject var model: ListeningPillModel

    private let pink = Color(
        red: 1.0,
        green: 0.15,
        blue: 0.58
    )

    private let barMultipliers: [CGFloat] = [
        0.20,
        0.28,
        0.42,
        0.62,
        0.82,
        1.00,
        0.82,
        0.62,
        0.42,
        0.28,
        0.20
    ]

    var body: some View {

        HStack(spacing: 0) {

            Text("V")
                .font(
                    .system(
                        size: 15,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(pink)
                .frame(
                    width: 22,
                    height: 26
                )

            Rectangle()
                .fill(
                    Color.white.opacity(0.12)
                )
                .frame(
                    width: 1,
                    height: 18
                )
                .padding(.horizontal, 6)

            HStack(
                alignment: .center,
                spacing: 2.5
            ) {

                ForEach(
                    Array(barMultipliers.enumerated()),
                    id: \.offset
                ) { _, multiplier in

                    waveformElement(
                        multiplier: multiplier
                    )
                }
            }
            .frame(
                width: 92,
                height: 24
            )
        }
        .padding(.horizontal, 8)
        .frame(
            width: 150,
            height: 36
        )
        .background(
            RoundedRectangle(
                cornerRadius: 13,
                style: .continuous
            )
            .fill(
                Color(
                    red: 13.0 / 255.0,
                    green: 13.0 / 255.0,
                    blue: 13.0 / 255.0
                )
            )
        )
        
    }

    @ViewBuilder
    private func waveformElement(
        multiplier: CGFloat
    ) -> some View {

        let level = CGFloat(
            max(
                0,
                min(
                    1,
                    model.audioLevel
                )
            )
        )

        let isQuiet = level < 0.08

        if isQuiet {

            Circle()
                .fill(
                    pink.opacity(0.68)
                )
                .frame(
                    width: 2.2,
                    height: 2.2
                )

        } else {

            let minimumHeight: CGFloat = 2.5
            let maximumHeight: CGFloat = 20

            let height =
                minimumHeight +
                (
                    maximumHeight -
                    minimumHeight
                )
                * level
                * multiplier

            Capsule()
                .fill(pink)
                .frame(
                    width: 2.5,
                    height: height
                )
                .shadow(
                    color: pink.opacity(0.35),
                    radius: 1.5
                )
                .animation(
                    .easeOut(duration: 0.05),
                    value: model.audioLevel
                )
        }
    }
}
