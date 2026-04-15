import Foundation

enum AppPaths {
    static let bundleIdentifier = "com.wisp.app"

    static var applicationSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Wisp", isDirectory: true)
    }

    static var recordingsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("Recordings", isDirectory: true)
    }

    static var transcriptsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("Transcripts", isDirectory: true)
    }

    static var modelsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("Models", isDirectory: true)
    }

    static func ensureDirectories() throws {
        let fm = FileManager.default
        for url in [applicationSupportDirectory, recordingsDirectory, transcriptsDirectory, modelsDirectory] {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    static func recordingURL(date: Date = .now) -> URL {
        uniqueFileURL(in: recordingsDirectory, prefix: "recording-\(timestamp(for: date))", pathExtension: "wav")
    }

    static func transcriptURL(date: Date = .now) -> URL {
        uniqueFileURL(in: transcriptsDirectory, prefix: "transcript-\(timestamp(for: date))", pathExtension: "txt")
    }

    static func transcriptURL(for audioURL: URL, date: Date = .now) -> URL {
        let recordingsFolder = recordingsDirectory.standardizedFileURL
        let audioFolder = audioURL.deletingLastPathComponent().standardizedFileURL
        let audioStem = audioURL.deletingPathExtension().lastPathComponent

        if audioFolder == recordingsFolder, audioStem.hasPrefix("recording-") {
            let suffix = String(audioStem.dropFirst("recording-".count))
            return uniqueFileURL(in: transcriptsDirectory, prefix: "transcript-\(suffix)", pathExtension: "txt")
        }

        let sanitizedStem = sanitize(audioURL.deletingPathExtension().lastPathComponent)
        return uniqueFileURL(
            in: transcriptsDirectory,
            prefix: "transcript-\(sanitizedStem)-\(timestamp(for: date))",
            pathExtension: "txt"
        )
    }

    static func recordingURL(forTranscriptURL transcriptURL: URL) -> URL? {
        let transcriptStem = transcriptURL.deletingPathExtension().lastPathComponent
        guard transcriptStem.hasPrefix("transcript-") else {
            return nil
        }

        let suffix = String(transcriptStem.dropFirst("transcript-".count))
        let candidate = recordingsDirectory.appendingPathComponent("recording-\(suffix).wav")
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }

    private static func timestamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    private static func uniqueFileURL(in directory: URL, prefix: String, pathExtension: String) -> URL {
        let fm = FileManager.default
        var candidate = directory.appendingPathComponent(prefix).appendingPathExtension(pathExtension)
        var counter = 1

        while fm.fileExists(atPath: candidate.path) {
            candidate = directory
                .appendingPathComponent("\(prefix)-\(counter)")
                .appendingPathExtension(pathExtension)
            counter += 1
        }

        return candidate
    }

    private static func sanitize(_ value: String) -> String {
        let reduced = value
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return reduced.isEmpty ? "audio" : reduced
    }
}
