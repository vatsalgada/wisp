import Foundation
import AppKit
import Observation
import OSLog
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

private let modelLogger = Logger(subsystem: "com.wisp.app", category: "model")

@MainActor
@Observable
final class AppModel {
    enum ThemePreference: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system:
                return "Match macOS"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            }
        }

        var symbolName: String {
            switch self {
            case .system:
                return "circle.lefthalf.filled"
            case .light:
                return "sun.max.fill"
            case .dark:
                return "moon.stars.fill"
            }
        }

        var preferredColorScheme: ColorScheme? {
            switch self {
            case .system:
                return nil
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
    }

    enum SidebarItem: String, CaseIterable, Identifiable {
        case capture
        case history
        case models
        case permissions
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .capture:
                return "Capture"
            case .history:
                return "History"
            case .models:
                return "Models"
            case .permissions:
                return "Permissions"
            case .settings:
                return "Settings"
            }
        }

        var symbolName: String {
            switch self {
            case .capture:
                return "mic.fill"
            case .history:
                return "clock.arrow.circlepath"
            case .models:
                return "cpu"
            case .permissions:
                return "lock.shield"
            case .settings:
                return "gearshape"
            }
        }
    }

    enum WorkflowState: String {
        case idle
        case preparing
        case recording
        case transcribing
        case ready
        case failed

        var displayName: String {
            switch self {
            case .idle:
                return "Idle"
            case .preparing:
                return "Preparing"
            case .recording:
                return "Recording"
            case .transcribing:
                return "Transcribing"
            case .ready:
                return "Ready"
            case .failed:
                return "Needs attention"
            }
        }
    }

    struct TranscriptRecord: Identifiable {
        let id = UUID()
        let createdAt: Date
        let text: String
        let audioFileURL: URL?
        let transcriptFileURL: URL
    }

    var selectedSidebarItem: SidebarItem? = .capture
    var selectedModel: LocalModel = .baseEnglish {
        didSet {
            defaults.set(selectedModel.rawValue, forKey: DefaultsKey.selectedModel.rawValue)
        }
    }
    var hotkey = "Command-Shift-D"
    var launchAtLogin = false {
        didSet {
            defaults.set(launchAtLogin, forKey: DefaultsKey.launchAtLogin.rawValue)
            guard launchAtLogin != oldValue else { return }
            syncLaunchAtLoginRegistration()
        }
    }
    var usePushToTalk = true {
        didSet {
            defaults.set(usePushToTalk, forKey: DefaultsKey.usePushToTalk.rawValue)
        }
    }
    var themePreference: ThemePreference = .system {
        didSet {
            defaults.set(themePreference.rawValue, forKey: DefaultsKey.themePreference.rawValue)
        }
    }

    var workflowState: WorkflowState = .idle
    var statusMessage = "Run a local dictation from the main window or the menu bar."
    var errorMessage: String?
    var latestTranscript = ""
    var transcriptHistory: [TranscriptRecord] = []
    var selectedTranscriptRecordID: TranscriptRecord.ID?
    var historySearchText = ""
    var lastRecordingURL: URL?
    var lastTranscriptFileURL: URL?
    var microphonePermission: PermissionState = .notDetermined
    var accessibilityTrusted = false
    var modelIsAvailable = false
    var modelPath = ""

    @ObservationIgnored private let recorder = AudioRecorder()
    @ObservationIgnored private let modelDownloader = ModelDownloader()
    @ObservationIgnored private let runtime: any TranscriptionRuntime = WhisperRuntime()
    @ObservationIgnored private let textInsertion = TextInsertionService()
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var isSyncingLaunchAtLoginRegistration = false

    private enum DefaultsKey: String {
        case selectedModel = "selectedModel"
        case launchAtLogin = "launchAtLogin"
        case usePushToTalk = "usePushToTalk"
        case themePreference = "themePreference"
    }

    init() {
        if let storedModel = defaults.string(forKey: DefaultsKey.selectedModel.rawValue),
           let model = LocalModel(rawValue: storedModel) {
            selectedModel = model
        }
        launchAtLogin = storedLaunchAtLoginPreference()
        if defaults.object(forKey: DefaultsKey.usePushToTalk.rawValue) != nil {
            usePushToTalk = defaults.bool(forKey: DefaultsKey.usePushToTalk.rawValue)
        }
        if let storedTheme = defaults.string(forKey: DefaultsKey.themePreference.rawValue),
           let theme = ThemePreference(rawValue: storedTheme) {
            themePreference = theme
        }

        refreshEnvironment()
        loadTranscriptHistoryFromDisk()
    }

    var isDictating: Bool {
        workflowState == .recording
    }

    var canStartDictation: Bool {
        workflowState == .idle || workflowState == .ready || workflowState == .failed
    }

    var canStopDictation: Bool {
        workflowState == .recording
    }

    var selectedTranscriptRecord: TranscriptRecord? {
        guard let selectedTranscriptRecordID else {
            return transcriptHistory.first
        }
        return transcriptHistory.first(where: { $0.id == selectedTranscriptRecordID }) ?? transcriptHistory.first
    }

    var filteredTranscriptHistory: [TranscriptRecord] {
        let query = historySearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return transcriptHistory }
        return transcriptHistory.filter { record in
            record.text.localizedCaseInsensitiveContains(query)
                || record.transcriptFileURL.lastPathComponent.localizedCaseInsensitiveContains(query)
        }
    }

    var latestTranscriptWordCount: Int {
        latestTranscript
            .split(whereSeparator: \.isWhitespace)
            .count
    }

    func refreshEnvironment() {
        do {
            try AppPaths.ensureDirectories()
        } catch {
            errorMessage = error.localizedDescription
        }

        microphonePermission = PermissionManager.microphoneStatus()
        accessibilityTrusted = PermissionManager.isAccessibilityTrusted(prompt: false)

        let runtimeStatus = runtime.status(for: selectedModel)
        modelIsAvailable = runtimeStatus.modelExists
        modelPath = runtimeStatus.modelURL.path
    }

    func toggleDictation() async {
        if isDictating {
            await stopDictation()
        } else {
            await startDictation()
        }
    }

    func handleHotKeyPress() async {
        if usePushToTalk {
            if !isDictating {
                await startDictation()
            }
        } else {
            await toggleDictation()
        }
    }

    func handleHotKeyRelease() async {
        guard usePushToTalk, isDictating else { return }
        await stopDictation()
    }

    func prepareModelIfNeeded() async {
        workflowState = .preparing
        errorMessage = nil
        statusMessage = "Checking the local model for \(selectedModel.displayName)…"

        do {
            let modelURL = try await modelDownloader.ensureModelAvailable(selectedModel)
            modelLogger.notice("Model ready at \(modelURL.path, privacy: .public)")
            modelIsAvailable = true
            modelPath = modelURL.path
            statusMessage = "Model \(selectedModel.displayName) is ready."
            if workflowState == .preparing {
                workflowState = .idle
            }
        } catch {
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Model preparation failed."
        }
    }

    func requestMicrophoneAccess() async {
        let granted = await PermissionManager.requestMicrophoneAccess()
        microphonePermission = granted ? .granted : .denied
        if granted {
            statusMessage = "Microphone access granted."
        } else {
            workflowState = .failed
            errorMessage = "Microphone access is required to record dictation."
        }
    }

    func requestAccessibilityAccess() {
        accessibilityTrusted = PermissionManager.isAccessibilityTrusted(prompt: true)
        statusMessage = accessibilityTrusted ? "Accessibility access granted." : "Accessibility access is still required for text insertion."
    }

    func openMicrophoneSettings() {
        openSettingsURL("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
    }

    func openAccessibilitySettings() {
        openSettingsURL("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func startDictation() async {
        guard canStartDictation else { return }

        refreshEnvironment()

        if microphonePermission == .notDetermined {
            await requestMicrophoneAccess()
        }

        guard microphonePermission == .granted else {
            workflowState = .failed
            errorMessage = "Microphone access is required before recording can begin."
            return
        }

        if !modelIsAvailable {
            await prepareModelIfNeeded()
        }

        guard modelIsAvailable else {
            workflowState = .failed
            return
        }

        do {
            let recordingURL = try recorder.startRecording()
            lastRecordingURL = recordingURL
            workflowState = .recording
            errorMessage = nil
            statusMessage = "Recording to \(recordingURL.lastPathComponent)…"
            modelLogger.notice("Recording started at \(recordingURL.path, privacy: .public)")
        } catch {
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Recording could not be started."
        }
    }

    func stopDictation() async {
        guard canStopDictation else { return }
        guard let recordingURL = recorder.stopRecording() else {
            workflowState = .failed
            errorMessage = "No recording file was available to transcribe."
            return
        }

        await transcribeAudioFile(at: recordingURL, statusPrefix: "Transcribing recording")
    }

    func copyLatestTranscript() {
        guard !latestTranscript.isEmpty else { return }
        textInsertion.copyToPasteboard(latestTranscript)
        statusMessage = "Transcript copied to the pasteboard."
    }

    func insertLatestTranscript() {
        guard !latestTranscript.isEmpty else { return }

        do {
            textInsertion.copyToPasteboard(latestTranscript)
            try textInsertion.insertFromPasteboard()
            statusMessage = "Transcript pasted into the active app."
        } catch {
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Insertion could not be completed."
        }
    }

    func updateSelectedModel(_ model: LocalModel) {
        selectedModel = model
        latestTranscript = latestTranscript
        refreshEnvironment()
        statusMessage = "Selected model: \(model.displayName)"
    }

    func updateThemePreference(_ preference: ThemePreference) {
        themePreference = preference
        statusMessage = "Appearance: \(preference.title)"
    }

    func transcribeFromOpenPanel() async {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio]

        guard panel.runModal() == .OK, let url = panel.url else {
            statusMessage = "File transcription was cancelled."
            return
        }

        await transcribeAudioFile(at: url, statusPrefix: "Transcribing file")
    }

    private func transcribeAudioFile(at audioURL: URL, statusPrefix: String) async {
        if !modelIsAvailable {
            await prepareModelIfNeeded()
        }

        guard modelIsAvailable else {
            workflowState = .failed
            return
        }

        lastRecordingURL = audioURL
        workflowState = .transcribing
        statusMessage = "\(statusPrefix) \(audioURL.lastPathComponent)…"
        modelLogger.notice("Beginning transcription for \(audioURL.path, privacy: .public)")

        do {
            let transcriptOutputURL = AppPaths.transcriptURL(for: audioURL)
            let result = try await runtime.transcribe(
                audioFileURL: audioURL,
                model: selectedModel,
                transcriptFileURL: transcriptOutputURL
            )
            latestTranscript = result.text
            lastTranscriptFileURL = result.transcriptFileURL
            transcriptHistory.insert(
                TranscriptRecord(
                    createdAt: Date(),
                    text: result.text,
                    audioFileURL: audioURL,
                    transcriptFileURL: result.transcriptFileURL
                ),
                at: 0
            )
            selectedTranscriptRecordID = transcriptHistory.first?.id
            workflowState = .ready
            errorMessage = nil
            statusMessage = "Transcript ready."
            modelLogger.notice("Transcription completed")
        } catch {
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Transcription failed."
        }
    }

    func selectTranscript(_ record: TranscriptRecord) {
        selectedTranscriptRecordID = record.id
        latestTranscript = record.text
        lastRecordingURL = record.audioFileURL
        lastTranscriptFileURL = record.transcriptFileURL
        selectedSidebarItem = .history
        statusMessage = "Loaded transcript from \(record.createdAt.formatted(date: .abbreviated, time: .shortened))."
    }

    func revealTranscriptInFinder(_ record: TranscriptRecord) {
        NSWorkspace.shared.activateFileViewerSelecting([record.transcriptFileURL])
    }

    func openTranscriptFile(_ record: TranscriptRecord) {
        NSWorkspace.shared.open(record.transcriptFileURL)
    }

    func copyTranscript(_ record: TranscriptRecord) {
        textInsertion.copyToPasteboard(record.text)
        statusMessage = "Transcript copied to the pasteboard."
    }

    func insertTranscript(_ record: TranscriptRecord) {
        do {
            textInsertion.copyToPasteboard(record.text)
            try textInsertion.insertFromPasteboard()
            statusMessage = "Transcript pasted into the active app."
        } catch {
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Insertion could not be completed."
        }
    }

    func deleteTranscript(_ record: TranscriptRecord) {
        do {
            try FileManager.default.removeItem(at: record.transcriptFileURL)
            if let audioFileURL = record.audioFileURL,
               audioFileURL.deletingLastPathComponent().standardizedFileURL == AppPaths.recordingsDirectory.standardizedFileURL,
               FileManager.default.fileExists(atPath: audioFileURL.path) {
                try? FileManager.default.removeItem(at: audioFileURL)
            }
            transcriptHistory.removeAll { $0.id == record.id }

            if selectedTranscriptRecordID == record.id {
                selectedTranscriptRecordID = transcriptHistory.first?.id
                if let nextRecord = transcriptHistory.first {
                    latestTranscript = nextRecord.text
                    lastTranscriptFileURL = nextRecord.transcriptFileURL
                    lastRecordingURL = nextRecord.audioFileURL
                } else {
                    latestTranscript = ""
                    lastTranscriptFileURL = nil
                    lastRecordingURL = nil
                }
            }

            statusMessage = "Transcript deleted."
        } catch {
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Transcript could not be deleted."
        }
    }

    func revealTranscriptFolder() {
        NSWorkspace.shared.open(AppPaths.transcriptsDirectory)
    }

    func revealModelInFinder() {
        guard modelIsAvailable else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedModel.localURL])
    }

    private func loadTranscriptHistoryFromDisk() {
        do {
            try AppPaths.ensureDirectories()
            let transcriptURLs = try FileManager.default.contentsOfDirectory(
                at: AppPaths.transcriptsDirectory,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
                .filter { $0.pathExtension == "txt" }
                .sorted { lhs, rhs in
                    let leftDate = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                    let rightDate = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                    return leftDate > rightDate
                }

            transcriptHistory = transcriptURLs.compactMap { url in
                guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                    return nil
                }

                let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
                let createdAt = values?.creationDate ?? values?.contentModificationDate ?? Date()
                return TranscriptRecord(
                    createdAt: createdAt,
                    text: text,
                    audioFileURL: AppPaths.recordingURL(forTranscriptURL: url),
                    transcriptFileURL: url
                )
            }

            if selectedTranscriptRecordID == nil, let first = transcriptHistory.first {
                selectedTranscriptRecordID = first.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func openSettingsURL(_ value: String) {
        guard let url = URL(string: value) else { return }
        NSWorkspace.shared.open(url)
    }

    private func storedLaunchAtLoginPreference() -> Bool {
        let savedPreference = defaults.bool(forKey: DefaultsKey.launchAtLogin.rawValue)

        do {
            let status = try launchAtLoginService().status
            switch status {
            case .enabled, .requiresApproval:
                return true
            case .notRegistered, .notFound:
                return false
            @unknown default:
                return savedPreference
            }
        } catch {
            return savedPreference
        }
    }

    private func syncLaunchAtLoginRegistration() {
        guard !isSyncingLaunchAtLoginRegistration else { return }
        isSyncingLaunchAtLoginRegistration = true
        defer { isSyncingLaunchAtLoginRegistration = false }

        do {
            let service = try launchAtLoginService()
            switch service.status {
            case .enabled where launchAtLogin:
                statusMessage = "Launch at login is enabled."
            case .enabled, .requiresApproval:
                try service.unregister()
                statusMessage = "Launch at login is disabled."
            case .notRegistered, .notFound:
                if launchAtLogin {
                    try service.register()
                    statusMessage = "Launch at login is enabled."
                } else {
                    statusMessage = "Launch at login is disabled."
                }
            @unknown default:
                if launchAtLogin {
                    try service.register()
                    statusMessage = "Launch at login is enabled."
                } else {
                    try service.unregister()
                    statusMessage = "Launch at login is disabled."
                }
            }
        } catch {
            defaults.set(!launchAtLogin, forKey: DefaultsKey.launchAtLogin.rawValue)
            launchAtLogin = !launchAtLogin
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Launch at login could not be updated."
        }
    }

    private func launchAtLoginService() throws -> SMAppService {
        if #available(macOS 13.0, *) {
            return .mainApp
        }

        throw NSError(
            domain: "Wisp.LaunchAtLogin",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Launch at login requires macOS 13 or newer."]
        )
    }
}
