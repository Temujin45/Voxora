import Foundation

final class OpenRouterTranscriber {

    private let endpoint = URL(
        string: "https://openrouter.ai/api/v1/audio/transcriptions"
    )!

    private let model = "mistralai/voxtral-mini-transcribe"

    func transcribe(
        audioURL: URL,
        apiKey: String
    ) async throws -> String {

        print("VOXORA: STARTING TRANSCRIPTION")

        // Read the WAV file
        let audioData = try Data(contentsOf: audioURL)

        print("VOXORA: AUDIO SIZE \(audioData.count) BYTES")

        // Convert audio to Base64
        let base64Audio = audioData.base64EncodedString()

        print("VOXORA: AUDIO ENCODED")

        // Build request
        var request = URLRequest(url: endpoint)

        request.httpMethod = "POST"

        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        // Identify Voxora to OpenRouter
        request.setValue(
            "Voxora",
            forHTTPHeaderField: "X-Title"
        )

        let requestBody = TranscriptionRequest(
            model: model,
            inputAudio: InputAudio(
                data: base64Audio,
                format: "wav"
            )
        )

        request.httpBody = try JSONEncoder().encode(
            requestBody
        )

        print("VOXORA: SENDING TO OPENROUTER")

        // Send request
        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }

        print(
            "VOXORA: OPENROUTER STATUS \(httpResponse.statusCode)"
        )

        // Handle API errors
        guard (200...299).contains(httpResponse.statusCode) else {

            let errorText = String(
                data: data,
                encoding: .utf8
            ) ?? "Unknown API error"

            print("VOXORA: API ERROR")
            print(errorText)

            throw OpenRouterError.apiError(
                statusCode: httpResponse.statusCode,
                message: errorText
            )
        }

        // Decode response
        let transcriptionResponse =
            try JSONDecoder().decode(
                TranscriptionResponse.self,
                from: data
            )

        print("VOXORA: TRANSCRIPTION RECEIVED")

        return transcriptionResponse.text
    }
}


// MARK: - Request Models

private struct TranscriptionRequest: Encodable {

    let model: String
    let inputAudio: InputAudio

    enum CodingKeys: String, CodingKey {
        case model
        case inputAudio = "input_audio"
    }
}

private struct InputAudio: Encodable {

    let data: String
    let format: String
}


// MARK: - Response Model

private struct TranscriptionResponse: Decodable {

    let text: String
}


// MARK: - Errors

enum OpenRouterError: LocalizedError {

    case invalidResponse

    case apiError(
        statusCode: Int,
        message: String
    )

    var errorDescription: String? {

        switch self {

        case .invalidResponse:
            return "OpenRouter returned an invalid response."

        case .apiError(let statusCode, let message):
            return "OpenRouter error \(statusCode): \(message)"
        }
    }
}
