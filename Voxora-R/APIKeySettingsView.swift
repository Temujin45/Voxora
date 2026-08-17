import SwiftUI

struct APIKeySettingsView: View {

    @State private var apiKey = ""
    @State private var statusMessage = ""

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("OpenRouter API Key")
                .font(.headline)

            SecureField(
                "sk-or-v1-...",
                text: $apiKey
            )
            .textFieldStyle(.roundedBorder)

            HStack {

                Button("Save API Key") {
                    saveAPIKey()
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Text("Your API key is stored securely in the macOS Keychain.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 500)
        .onAppear {
            loadExistingKey()
        }
    }

    private func loadExistingKey() {

        do {
            apiKey = try KeychainManager.shared.loadAPIKey()
            statusMessage = "API key saved"
        } catch {
            // No key saved yet.
            apiKey = ""
        }
    }

    private func saveAPIKey() {

        let trimmedKey = apiKey.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedKey.isEmpty else {
            statusMessage = "Enter an API key."
            return
        }

        do {

            try KeychainManager.shared.saveAPIKey(
                trimmedKey
            )

            apiKey = trimmedKey
            statusMessage = "Saved ✓"

        } catch {

            statusMessage = "Could not save key."
            print("VOXORA: KEYCHAIN ERROR \(error)")
        }
    }
}
