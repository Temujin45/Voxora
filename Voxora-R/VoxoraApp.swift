import SwiftUI

@main
struct VoxoraApp: App {
    
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("Voxora", systemImage: "mic.fill") {
            VoxoraMenuView(appState: appState)
        }
        .menuBarExtraStyle(.menu)

        Window("Voxora Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}
