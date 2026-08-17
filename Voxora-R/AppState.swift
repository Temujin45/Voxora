import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {

    @Published var isListening = false

    let hotkeyManager = GlobalHotkeyManager()
    let audioRecorder = AudioRecorder()
    let audioProcessor = AudioProcessor()
    let transcriber = OpenRouterTranscriber()
    let textInserter = TextInserter()

    // Floating Voxora listening pill
    let listeningPill = ListeningPillWindow()

    init() {

        // Hotkey pressed
        hotkeyManager.onKeyDown = { [weak self] in
            Task { @MainActor in
                self?.startListening()
            }
        }

        // Hotkey released
        hotkeyManager.onKeyUp = { [weak self] in
            Task { @MainActor in
                self?.stopListening()
            }
        }

        // Recording finished
        audioRecorder.onRecordingFinished = { [weak self] url in
            Task { @MainActor in
                self?.processRecording(url)
            }
        }

        // Live microphone volume → floating waveform
        audioRecorder.onAudioLevel = { [weak self] level in
            Task { @MainActor in
                self?.listeningPill.updateAudioLevel(level)
            }
        }

        // Start listening for the global hotkey
        hotkeyManager.start()

        // Ask/check microphone permission once when Voxora launches
        Task {
            _ = await audioRecorder.requestPermission()
        }
        if !AccessibilityManager.shared.isTrusted() {

            print(
                "VOXORA: REQUESTING ACCESSIBILITY PERMISSION"
            )

            AccessibilityManager.shared.requestPermission()

        } else {

            print(
                "VOXORA: ACCESSIBILITY PERMISSION GRANTED"
            )
        }
    }

    // MARK: - Start Listening

    private func startListening() {

        guard !isListening else {
            return
        }

        textInserter.captureTargetApplication()
        
        print("VOXORA: HOTKEY DOWN")
        
        textInserter.captureTargetApplication()

        isListening = true

        // Show floating pill
        listeningPill.showPill()

        do {

            try audioRecorder.startRecording()

        } catch {

            print("VOXORA: FAILED TO START RECORDING")
            print("VOXORA: \(error)")

            isListening = false

            // Don't leave the pill on screen if recording fails
            listeningPill.hidePill()
        }
    }

    // MARK: - Stop Listening

    private func stopListening() {

        guard isListening else {
            return
        }

        print("VOXORA: HOTKEY UP")

        isListening = false

        // Hide immediately when hotkey is released
        listeningPill.hidePill()

        audioRecorder.stopRecording()
    }

    // MARK: - Process Recording

    private func processRecording(_ url: URL) {

        print("VOXORA: PROCESSING RECORDING")

        Task {

            do {

                // Convert CAF → 16 kHz mono WAV
                let wavURL =
                    try audioProcessor
                        .convertToTranscriptionFormat(
                            inputURL: url
                        )

                print("VOXORA: READY FOR TRANSCRIPTION")
                print("VOXORA: WAV FILE")
                print(wavURL.path)

                // Get API key from Keychain
                let apiKey =
                    try KeychainManager.shared.loadAPIKey()

                print("VOXORA: API KEY FOUND")

                // Send audio to Voxtral
                let transcript =
                    try await transcriber.transcribe(
                        audioURL: wavURL,
                        apiKey: apiKey
                    )

                print("VOXORA: ========================")
                print("VOXORA: TRANSCRIPT")
                print(transcript)
                print("VOXORA: ========================")

                // Insert transcript
                textInserter.insertText(transcript)

            } catch {

                print("VOXORA: TRANSCRIPTION FAILED")
                print("VOXORA: \(error)")
            }
        }
    }
}
