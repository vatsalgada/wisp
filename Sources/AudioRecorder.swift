import AVFoundation
import Foundation

enum AudioRecorderError: LocalizedError {
    case recorderUnavailable
    case failedToStart

    var errorDescription: String? {
        switch self {
        case .recorderUnavailable:
            return "The recorder could not be created."
        case .failedToStart:
            return "Recording could not be started."
        }
    }
}

final class AudioRecorder: NSObject {
    private var recorder: AVAudioRecorder?
    private(set) var currentRecordingURL: URL?

    var isRecording: Bool {
        recorder?.isRecording ?? false
    }

    func startRecording() throws -> URL {
        try AppPaths.ensureDirectories()

        let url = AppPaths.recordingURL()
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()

        guard recorder.record() else {
            throw AudioRecorderError.failedToStart
        }

        self.recorder = recorder
        currentRecordingURL = url
        return url
    }

    func stopRecording() -> URL? {
        recorder?.stop()
        recorder = nil
        defer { currentRecordingURL = nil }
        return currentRecordingURL
    }
}
