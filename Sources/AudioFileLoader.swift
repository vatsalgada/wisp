@preconcurrency import AVFoundation
import Foundation

enum AudioFileLoaderError: LocalizedError {
    case failedToConvert
    case missingBuffer

    var errorDescription: String? {
        switch self {
        case .failedToConvert:
            return "The recorded audio could not be converted into Whisper samples."
        case .missingBuffer:
            return "The converted audio buffer was empty."
        }
    }
}

private final class ConversionInputState: @unchecked Sendable {
    var didProvideInput = false
}

enum AudioFileLoader {
    static func loadWhisperSamples(from url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let inputFormat = file.processingFormat
        let inputFrameCount = AVAudioFrameCount(file.length)
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: inputFrameCount) else {
            throw AudioFileLoaderError.missingBuffer
        }

        try file.read(into: inputBuffer)

        guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false),
              let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw AudioFileLoaderError.failedToConvert
        }

        let ratio = outputFormat.sampleRate / inputFormat.sampleRate
        let outputCapacity = AVAudioFrameCount((Double(inputFrameCount) * ratio) + 2048)
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputCapacity) else {
            throw AudioFileLoaderError.missingBuffer
        }

        let inputState = ConversionInputState()
        var conversionError: NSError?
        let status = converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
            if inputState.didProvideInput {
                outStatus.pointee = .noDataNow
                return nil
            } else {
                inputState.didProvideInput = true
                outStatus.pointee = .haveData
                return inputBuffer
            }
        }

        if status == .error || conversionError != nil {
            throw conversionError ?? AudioFileLoaderError.failedToConvert
        }

        guard let channelData = outputBuffer.floatChannelData?.pointee else {
            throw AudioFileLoaderError.missingBuffer
        }

        let frameLength = Int(outputBuffer.frameLength)
        return Array(UnsafeBufferPointer(start: channelData, count: frameLength))
    }
}
