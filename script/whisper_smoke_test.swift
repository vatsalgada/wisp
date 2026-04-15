import AVFoundation
import Foundation
import whisper

enum SmokeTestError: Error {
    case usage
    case failedToConvert
    case emptyTranscript
    case failedToLoadModel
    case failedToTranscribe
}

func loadWhisperSamples(from url: URL) throws -> [Float] {
    let file = try AVAudioFile(forReading: url)
    let inputFormat = file.processingFormat
    let inputFrameCount = AVAudioFrameCount(file.length)
    guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: inputFrameCount) else {
        throw SmokeTestError.failedToConvert
    }

    try file.read(into: inputBuffer)

    guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false),
          let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
        throw SmokeTestError.failedToConvert
    }

    let ratio = outputFormat.sampleRate / inputFormat.sampleRate
    let outputCapacity = AVAudioFrameCount((Double(inputFrameCount) * ratio) + 2048)
    guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputCapacity) else {
        throw SmokeTestError.failedToConvert
    }

    var didProvideInput = false
    var conversionError: NSError?
    let status = converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
        if didProvideInput {
            outStatus.pointee = .noDataNow
            return nil
        } else {
            didProvideInput = true
            outStatus.pointee = .haveData
            return inputBuffer
        }
    }

    if status == .error || conversionError != nil {
        throw conversionError ?? SmokeTestError.failedToConvert
    }

    guard let channelData = outputBuffer.floatChannelData?.pointee else {
        throw SmokeTestError.failedToConvert
    }

    return Array(UnsafeBufferPointer(start: channelData, count: Int(outputBuffer.frameLength)))
}

func transcribe(modelURL: URL, audioURL: URL) throws -> String {
    var contextParams = whisper_context_default_params()
    contextParams.flash_attn = true

    guard let context = modelURL.path.withCString({ whisper_init_from_file_with_params($0, contextParams) }) else {
        throw SmokeTestError.failedToLoadModel
    }
    defer { whisper_free(context) }

    var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
    "en".withCString { languageCString in
        params.print_realtime = false
        params.print_progress = false
        params.print_timestamps = false
        params.print_special = false
        params.translate = false
        params.language = languageCString
        params.n_threads = Int32(max(1, min(8, ProcessInfo.processInfo.processorCount - 2)))
        params.no_context = true
    }

    let samples = try loadWhisperSamples(from: audioURL)
    let result = samples.withUnsafeBufferPointer { buffer in
        whisper_full(context, params, buffer.baseAddress, Int32(buffer.count))
    }

    guard result == 0 else {
        throw SmokeTestError.failedToTranscribe
    }

    let count = whisper_full_n_segments(context)
    var parts: [String] = []
    for index in 0..<count {
        parts.append(String(cString: whisper_full_get_segment_text(context, index)).trimmingCharacters(in: .whitespacesAndNewlines))
    }

    let transcript = parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !transcript.isEmpty else {
        throw SmokeTestError.emptyTranscript
    }

    return transcript
}

do {
    guard CommandLine.arguments.count == 3 else {
        throw SmokeTestError.usage
    }

    let modelURL = URL(fileURLWithPath: CommandLine.arguments[1])
    let audioURL = URL(fileURLWithPath: CommandLine.arguments[2])
    let transcript = try transcribe(modelURL: modelURL, audioURL: audioURL)
    print(transcript)
} catch {
    fputs("whisper smoke test failed: \(error)\n", stderr)
    exit(1)
}
