import Foundation
import whisper

enum WhisperRuntimeError: LocalizedError {
    case failedToLoadModel
    case transcriptionFailed
    case emptyTranscript

    var errorDescription: String? {
        switch self {
        case .failedToLoadModel:
            return "The Whisper model could not be loaded."
        case .transcriptionFailed:
            return "Whisper failed to transcribe the recorded audio."
        case .emptyTranscript:
            return "Whisper returned an empty transcript."
        }
    }
}

final class WhisperContextBox: @unchecked Sendable {
    private let lock = NSLock()
    private var context: OpaquePointer?
    private var loadedModelPath: String?

    deinit {
        if let context {
            whisper_free(context)
        }
    }

    func transcription(for samples: [Float], modelURL: URL) throws -> String {
        lock.lock()
        defer { lock.unlock() }

        try loadContextIfNeeded(from: modelURL)

        guard let context else {
            throw WhisperRuntimeError.failedToLoadModel
        }

        let maxThreads = Int32(max(1, min(8, ProcessInfo.processInfo.processorCount - 2)))
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)

        "en".withCString { languageCString in
            params.print_realtime = false
            params.print_progress = false
            params.print_timestamps = false
            params.print_special = false
            params.translate = false
            params.language = languageCString
            params.n_threads = maxThreads
            params.offset_ms = 0
            params.no_context = true
            params.single_segment = false
        }

        whisper_reset_timings(context)

        let result = samples.withUnsafeBufferPointer { buffer -> Int32 in
            whisper_full(context, params, buffer.baseAddress, Int32(buffer.count))
        }

        guard result == 0 else {
            throw WhisperRuntimeError.transcriptionFailed
        }

        var segments: [String] = []
        let count = whisper_full_n_segments(context)
        for index in 0..<count {
            let text = String(cString: whisper_full_get_segment_text(context, index))
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                segments.append(text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        let finalText = segments.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalText.isEmpty else {
            throw WhisperRuntimeError.emptyTranscript
        }

        return finalText
    }

    private func loadContextIfNeeded(from modelURL: URL) throws {
        if loadedModelPath == modelURL.path, context != nil {
            return
        }

        if let context {
            whisper_free(context)
            self.context = nil
        }

        var contextParams = whisper_context_default_params()
        contextParams.flash_attn = true

        let loaded = modelURL.path.withCString { cString in
            whisper_init_from_file_with_params(cString, contextParams)
        }

        guard let loaded else {
            throw WhisperRuntimeError.failedToLoadModel
        }

        context = loaded
        loadedModelPath = modelURL.path
    }
}

struct WhisperRuntime: TranscriptionRuntime {
    private let contextBox = WhisperContextBox()

    func status(for model: LocalModel) -> RuntimeStatus {
        RuntimeStatus(
            modelExists: model.isUsableFile(at: model.localURL),
            modelURL: model.localURL
        )
    }

    func transcribe(audioFileURL: URL, model: LocalModel, transcriptFileURL: URL) async throws -> TranscriptResult {
        let samples = try AudioFileLoader.loadWhisperSamples(from: audioFileURL)
        let text = try contextBox.transcription(for: samples, modelURL: model.localURL)

        try AppPaths.ensureDirectories()
        try text.write(to: transcriptFileURL, atomically: true, encoding: .utf8)

        return TranscriptResult(text: text, transcriptFileURL: transcriptFileURL)
    }
}
