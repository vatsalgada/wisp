import Foundation

enum LocalModel: String, CaseIterable, Identifiable, Sendable {
    case tinyEnglish = "tiny.en"
    case baseEnglish = "base.en"
    case smallEnglish = "small.en"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var fileName: String {
        "ggml-\(rawValue).bin"
    }

    var downloadURL: URL {
        URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(fileName)")!
    }

    var recommendedLabel: String {
        switch self {
        case .tinyEnglish:
            return "fastest"
        case .baseEnglish:
            return "balanced"
        case .smallEnglish:
            return "better quality"
        }
    }

    var summary: String {
        switch self {
        case .tinyEnglish:
            return "Snappy local dictation for quick notes and low-latency capture."
        case .baseEnglish:
            return "The best default mix of speed, quality, and download size."
        case .smallEnglish:
            return "Higher accuracy for longer recordings when you can spare more compute."
        }
    }

    var approximateSize: String {
        switch self {
        case .tinyEnglish:
            return "~75 MB"
        case .baseEnglish:
            return "~148 MB"
        case .smallEnglish:
            return "~466 MB"
        }
    }

    var minimumExpectedFileSize: Int64 {
        switch self {
        case .tinyEnglish:
            return 50_000_000
        case .baseEnglish:
            return 100_000_000
        case .smallEnglish:
            return 300_000_000
        }
    }

    var localURL: URL {
        AppPaths.modelsDirectory.appendingPathComponent(fileName)
    }

    func isUsableFile(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path),
              let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let fileSize = values.fileSize else {
            return false
        }

        return Int64(fileSize) >= minimumExpectedFileSize
    }
}
