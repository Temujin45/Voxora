import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text("Voxora Settings")
                .font(.title2)
                .fontWeight(.semibold)

            APIKeySettingsView()

            Spacer()
        }
        .padding(24)
        .frame(width: 550, height: 400)
    }
}
