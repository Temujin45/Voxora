import AVFoundation
import Foundation

final class AudioRecorder {

    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?

    private(set) var recordingURL: URL?

    // Called when recording finishes.
    var onRecordingFinished: ((URL) -> Void)?

    // Sends microphone volume to the listening pill.
    var onAudioLevel: ((Float) -> Void)?

    // Prevents us from updating the UI too frequently.
    private var lastAudioLevelUpdate: TimeInterval = 0

    // MARK: - Microphone Permission

    func microphonePermissionStatus()
        -> AVAudioApplication.recordPermission {

        AVAudioApplication.shared.recordPermission
    }

    func requestPermission() async -> Bool {

        let status =
            AVAudioApplication.shared.recordPermission

        switch status {

        case .granted:

            print(
                "VOXORA: MICROPHONE PERMISSION ALREADY GRANTED"
            )

            return true

        case .denied:

            print(
                "VOXORA: MICROPHONE PERMISSION DENIED"
            )

            return false

        case .undetermined:

            print(
                "VOXORA: REQUESTING MICROPHONE PERMISSION"
            )

            let granted =
                await AVAudioApplication
                    .requestRecordPermission()

            if granted {

                print(
                    "VOXORA: MICROPHONE PERMISSION GRANTED"
                )

            } else {

                print(
                    "VOXORA: MICROPHONE PERMISSION DENIED"
                )
            }

            return granted

        @unknown default:

            print(
                "VOXORA: UNKNOWN MICROPHONE PERMISSION STATE"
            )

            return false
        }
    }

    // MARK: - Start Recording

    func startRecording() throws {

        guard !audioEngine.isRunning else {
            return
        }

        let inputNode =
            audioEngine.inputNode

        let inputFormat =
            inputNode.outputFormat(
                forBus: 0
            )

        let recordingsDirectory =
            FileManager.default
                .temporaryDirectory
                .appendingPathComponent(
                    "VoxoraRecordings",
                    isDirectory: true
                )

        try FileManager.default.createDirectory(
            at: recordingsDirectory,
            withIntermediateDirectories: true
        )

        let fileURL =
            recordingsDirectory
                .appendingPathComponent(
                    "recording-\(UUID().uuidString).caf"
                )

        recordingURL = fileURL

        audioFile =
            try AVAudioFile(
                forWriting: fileURL,
                settings: inputFormat.settings
            )

        inputNode.removeTap(
            onBus: 0
        )

        // Reset the audio-level timer.
        lastAudioLevelUpdate = 0

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: inputFormat
        ) { [weak self] buffer, _ in

            guard let self else {
                return
            }

            // MARK: Save Audio

            do {

                try self.audioFile?.write(
                    from: buffer
                )

            } catch {

                print(
                    "VOXORA AUDIO ERROR: \(error)"
                )
            }

            // MARK: Calculate Microphone Level

            let level =
                self.calculateAudioLevel(
                    from: buffer
                )

            let now =
                Date.timeIntervalSinceReferenceDate

            // Update the pill about 20 times per second.
            if now -
                self.lastAudioLevelUpdate >= 0.05 {

                self.lastAudioLevelUpdate = now

                self.onAudioLevel?(level)
            }
        }

        audioEngine.prepare()

        try audioEngine.start()

        print(
            "VOXORA: RECORDING STARTED"
        )

        print(
            "VOXORA: FILE \(fileURL.path)"
        )
    }

    // MARK: - Stop Recording

    func stopRecording() {

        guard audioEngine.isRunning else {
            return
        }

        audioEngine.inputNode.removeTap(
            onBus: 0
        )

        audioEngine.stop()

        audioFile = nil

        // Tell the pill that we're no longer receiving audio.
        onAudioLevel?(0)

        print(
            "VOXORA: RECORDING STOPPED"
        )

        if let recordingURL {

            print(
                "VOXORA: SAVED \(recordingURL.path)"
            )

            onRecordingFinished?(
                recordingURL
            )
        }
    }

    // MARK: - Calculate Audio Level

    private func calculateAudioLevel(
        from buffer: AVAudioPCMBuffer
    ) -> Float {

        guard
            let channelData =
                buffer.floatChannelData?.pointee
        else {
            return 0
        }

        let frameLength =
            Int(buffer.frameLength)

        guard frameLength > 0 else {
            return 0
        }

        var sum: Float = 0

        for index in 0..<frameLength {

            let sample =
                channelData[index]

            sum +=
                sample * sample
        }

        // RMS = root mean square.
        let rms =
            sqrt(
                sum /
                Float(frameLength)
            )

        guard rms > 0.00001 else {
            return 0
        }

        // Convert RMS to decibels.
        let decibels =
            20 *
            log10(rms)

        // Convert approximately:
        //
        // -50 dB = 0
        //  -5 dB = 1
        //
        // into a 0...1 value.
        let normalized =
            (decibels + 50) / 45

        return max(
            0,
            min(
                1,
                normalized
            )
        )
    }
}
