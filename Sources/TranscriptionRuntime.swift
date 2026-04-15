import Foundation

struct RuntimeStatus: Sendable {
    let modelExists: Bool
    let modelURL: URL
}

struct TranscriptResult: Sendable {
    let text: String
    let transcriptFileURL: URL
}

protocol TranscriptionRuntime: Sendable {
    func status(for model: LocalModel) -> RuntimeStatus
    func transcribe(audioFileURL: URL, model: LocalModel, transcriptFileURL: URL) async throws -> TranscriptResult
}
