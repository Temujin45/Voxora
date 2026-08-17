import AVFoundation
import Foundation

final class AudioProcessor {

    func convertToTranscriptionFormat(
        inputURL: URL
    ) throws -> URL {

        print("VOXORA: OPENING AUDIO FILE")

        let inputFile = try AVAudioFile(
            forReading: inputURL
        )

        let inputFormat = inputFile.processingFormat

        print("VOXORA: INPUT SAMPLE RATE \(inputFormat.sampleRate)")
        print("VOXORA: INPUT CHANNELS \(inputFormat.channelCount)")
        print("VOXORA: INPUT FRAMES \(inputFile.length)")

        // Desired transcription format:
        // 16,000 Hz
        // Mono
        // 16-bit PCM
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        )

        guard let outputFormat else {
            throw AudioProcessingError.couldNotCreateOutputFormat
        }

        print("VOXORA: OUTPUT SAMPLE RATE \(outputFormat.sampleRate)")
        print("VOXORA: OUTPUT CHANNELS \(outputFormat.channelCount)")

        guard let converter = AVAudioConverter(
            from: inputFormat,
            to: outputFormat
        ) else {
            throw AudioProcessingError.couldNotCreateConverter
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "voxora-\(UUID().uuidString).wav"
            )

        // Explicitly create a WAV file using the desired
        // 16-bit PCM processing format.
        let outputFile = try AVAudioFile(
            forWriting: outputURL,
            settings: outputFormat.settings,
            commonFormat: .pcmFormatInt16,
            interleaved: false
        )

        // Read the entire input recording.
        let inputFrameCount = AVAudioFrameCount(
            inputFile.length
        )

        guard inputFrameCount > 0 else {
            throw AudioProcessingError.emptyInput
        }

        guard let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: inputFormat,
            frameCapacity: inputFrameCount
        ) else {
            throw AudioProcessingError.couldNotCreateInputBuffer
        }

        try inputFile.read(
            into: inputBuffer
        )

        print(
            "VOXORA: READ \(inputBuffer.frameLength) INPUT FRAMES"
        )

        // Give the converter enough room for the resampled audio.
        let ratio =
            outputFormat.sampleRate /
            inputFormat.sampleRate

        let outputFrameCapacity =
            AVAudioFrameCount(
                ceil(
                    Double(inputBuffer.frameLength) * ratio
                )
            ) + 1024

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: outputFrameCapacity
        ) else {
            throw AudioProcessingError.couldNotCreateOutputBuffer
        }

        var conversionError: NSError?
        var suppliedInput = false

        let status = converter.convert(
            to: outputBuffer,
            error: &conversionError
        ) { _, inputStatus in

            if suppliedInput {
                inputStatus.pointee = .endOfStream
                return nil
            }

            suppliedInput = true
            inputStatus.pointee = .haveData

            return inputBuffer
        }

        if let conversionError {
            throw conversionError
        }

        guard status != .error else {
            throw AudioProcessingError.conversionFailed
        }

        guard outputBuffer.frameLength > 0 else {
            throw AudioProcessingError.noOutputFrames
        }

        print(
            "VOXORA: CONVERTER PRODUCED \(outputBuffer.frameLength) FRAMES"
        )

        // Write the converted PCM data to the WAV file.
        try outputFile.write(
            from: outputBuffer
        )

        outputFile.close()

        print("VOXORA: AUDIO CONVERTED")
        print("VOXORA: OUTPUT \(outputURL.path)")
        print("VOXORA: SAMPLE RATE \(outputFormat.sampleRate)")
        print("VOXORA: CHANNELS \(outputFormat.channelCount)")
        print("VOXORA: WAV CREATED SUCCESSFULLY")

        return outputURL
    }
}


// MARK: - Errors

enum AudioProcessingError: LocalizedError {

    case couldNotCreateOutputFormat
    case couldNotCreateConverter
    case emptyInput
    case couldNotCreateInputBuffer
    case couldNotCreateOutputBuffer
    case conversionFailed
    case noOutputFrames

    var errorDescription: String? {

        switch self {

        case .couldNotCreateOutputFormat:
            return "Could not create 16 kHz mono output format."

        case .couldNotCreateConverter:
            return "Could not create audio converter."

        case .emptyInput:
            return "The recording contains no audio frames."

        case .couldNotCreateInputBuffer:
            return "Could not create the input audio buffer."

        case .couldNotCreateOutputBuffer:
            return "Could not create the output audio buffer."

        case .conversionFailed:
            return "Audio conversion failed."

        case .noOutputFrames:
            return "The audio converter produced no output frames."
        }
    }
}
