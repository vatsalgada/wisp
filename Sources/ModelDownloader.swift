import Foundation

enum ModelDownloaderError: LocalizedError {
    case invalidDownload

    var errorDescription: String? {
        switch self {
        case .invalidDownload:
            return "The model download did not produce a usable file."
        }
    }
}

actor ModelDownloader {
    func ensureModelAvailable(_ model: LocalModel) async throws -> URL {
        try AppPaths.ensureDirectories()

        let destination = model.localURL
        if model.isUsableFile(at: destination) {
            return destination
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        let temporaryURL = try await download(model)
        try moveDownloadedModel(from: temporaryURL, to: destination, model: model)
        return destination
    }

    private func download(_ model: LocalModel) async throws -> URL {
        let (temporaryURL, response) = try await URLSession.shared.download(from: model.downloadURL)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ModelDownloaderError.invalidDownload
        }
        return temporaryURL
    }

    private func moveDownloadedModel(from temporaryURL: URL, to destination: URL, model: LocalModel) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: destination.path) {
            try fm.removeItem(at: destination)
        }
        try fm.moveItem(at: temporaryURL, to: destination)
        guard model.isUsableFile(at: destination) else {
            try? fm.removeItem(at: destination)
            throw ModelDownloaderError.invalidDownload
        }
    }
}
