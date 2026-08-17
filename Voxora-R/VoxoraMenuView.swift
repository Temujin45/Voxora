import SwiftUI

struct VoxoraMenuView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Text("Voxora")
                .font(.headline)

            if appState.isListening {
                Text("● Listening")
                    .foregroundStyle(.red)
            } else {
                Text("Ready")
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Settings…") {
                openWindow(id: "settings")
            }

            Divider()

            Button("Quit Voxora") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 220)
    }
}
