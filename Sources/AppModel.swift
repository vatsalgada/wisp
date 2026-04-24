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
        case clipboard
        case history
        case models
        case permissions
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .capture:
                return "Capture"
            case .clipboard:
                return "Clipboard"
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
            case .clipboard:
                return "doc.on.clipboard"
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
        let id: UUID
        let createdAt: Date
        var text: String
        let audioFileURL: URL?
        let transcriptFileURL: URL

        init(
            id: UUID = UUID(),
            createdAt: Date,
            text: String,
            audioFileURL: URL?,
            transcriptFileURL: URL
        ) {
            self.id = id
            self.createdAt = createdAt
            self.text = text
            self.audioFileURL = audioFileURL
            self.transcriptFileURL = transcriptFileURL
        }
    }

    struct ClipboardClip: Identifiable, Codable, Equatable {
        let id: UUID
        let createdAt: Date
        let text: String
        let source: String

        init(id: UUID = UUID(), createdAt: Date = Date(), text: String, source: String) {
            self.id = id
            self.createdAt = createdAt
            self.text = text
            self.source = source
        }
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
    var rememberCopiedText = false {
        didSet {
            defaults.set(rememberCopiedText, forKey: DefaultsKey.rememberCopiedText.rawValue)
            if rememberCopiedText {
                startPasteboardMonitoring()
            } else {
                stopPasteboardMonitoring()
            }
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
    var clipboardClips: [ClipboardClip] = []
    var selectedClipboardClipID: ClipboardClip.ID?
    var clipboardSearchText = ""
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
    @ObservationIgnored private let mediaPlayback = MediaPlaybackCoordinator()
    @ObservationIgnored private let dictationOverlay = DictationOverlayController()
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var isSyncingLaunchAtLoginRegistration = false
    @ObservationIgnored private var pasteboardMonitorTimer: Timer?
    @ObservationIgnored private var lastObservedPasteboardChangeCount = NSPasteboard.general.changeCount
    @ObservationIgnored private var insertAfterCurrentDictation = false
    @ObservationIgnored private weak var insertionTargetApplication: NSRunningApplication?

    private enum DefaultsKey: String {
        case selectedModel = "selectedModel"
        case launchAtLogin = "launchAtLogin"
        case usePushToTalk = "usePushToTalk"
        case rememberCopiedText = "rememberCopiedText"
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
        if defaults.object(forKey: DefaultsKey.rememberCopiedText.rawValue) != nil {
            rememberCopiedText = defaults.bool(forKey: DefaultsKey.rememberCopiedText.rawValue)
        }
        if let storedTheme = defaults.string(forKey: DefaultsKey.themePreference.rawValue),
           let theme = ThemePreference(rawValue: storedTheme) {
            themePreference = theme
        }

        refreshEnvironment()
        loadTranscriptHistoryFromDisk()
        loadClipboardClipsFromDisk()
        if rememberCopiedText {
            startPasteboardMonitoring()
        }
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

    var selectedClipboardClip: ClipboardClip? {
        guard let selectedClipboardClipID else {
            return clipboardClips.first
        }
        return clipboardClips.first(where: { $0.id == selectedClipboardClipID }) ?? clipboardClips.first
    }

    var filteredClipboardClips: [ClipboardClip] {
        let query = clipboardSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return clipboardClips }
        return clipboardClips.filter { clip in
            clip.text.localizedCaseInsensitiveContains(query)
                || clip.source.localizedCaseInsensitiveContains(query)
        }
    }

    var latestTranscriptWordCount: Int {
        latestTranscript
            .split(whereSeparator: \.isWhitespace)
            .count
    }

    var installedModels: [LocalModel] {
        LocalModel.allCases.filter { model in
            isModelInstalled(model)
        }
    }

    var downloadableModels: [LocalModel] {
        LocalModel.allCases.filter { !isModelInstalled($0) }
    }

    var selectedModelIsInstalled: Bool {
        isModelInstalled(selectedModel)
    }

    var installedModelCountText: String {
        let count = installedModels.count
        return count == 1 ? "1 installed" : "\(count) installed"
    }

    var installedModelsStorageText: String {
        ByteCountFormatter.string(
            fromByteCount: installedModels.reduce(into: Int64(0)) { total, model in
                total += modelFileSize(for: model)
            },
            countStyle: .file
        )
    }

    func isModelInstalled(_ model: LocalModel) -> Bool {
        model.isUsableFile(at: model.localURL)
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
                await startDictation(insertAfterTranscription: true)
            }
        } else {
            if isDictating {
                await stopDictation()
            } else {
                await startDictation(insertAfterTranscription: true)
            }
        }
    }

    func handleHotKeyRelease() async {
        guard usePushToTalk, isDictating else { return }
        await stopDictation()
    }

    func prepareModelIfNeeded() async {
        await downloadModel(selectedModel)
    }

    func downloadModel(_ model: LocalModel) async {
        workflowState = .preparing
        errorMessage = nil
        statusMessage = isModelInstalled(model)
            ? "Checking \(model.displayName)…"
            : "Downloading \(model.displayName)…"

        do {
            let modelURL = try await modelDownloader.ensureModelAvailable(model)
            modelLogger.notice("Model ready at \(modelURL.path, privacy: .public)")
            if selectedModel == model {
                modelIsAvailable = true
                modelPath = modelURL.path
            } else {
                refreshEnvironment()
            }
            statusMessage = "\(model.displayName) is ready."
            if workflowState == .preparing {
                workflowState = .idle
            }
        } catch {
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "\(model.displayName) could not be downloaded."
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
        statusMessage = accessibilityTrusted ? "Accessibility access granted." : "Accessibility access is still needed to paste."
    }

    func openMicrophoneSettings() {
        openSettingsURL("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
    }

    func openAccessibilitySettings() {
        openSettingsURL("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func startDictation(insertAfterTranscription: Bool = false) async {
        guard canStartDictation else { return }
        insertAfterCurrentDictation = insertAfterTranscription
        insertionTargetApplication = insertAfterTranscription ? currentInsertionTargetApplication() : nil

        refreshEnvironment()

        if microphonePermission == .notDetermined {
            await requestMicrophoneAccess()
        }

        guard microphonePermission == .granted else {
            insertAfterCurrentDictation = false
            workflowState = .failed
            errorMessage = "Microphone access is required before recording can begin."
            return
        }

        if !modelIsAvailable {
            await prepareModelIfNeeded()
        }

        guard modelIsAvailable else {
            insertAfterCurrentDictation = false
            workflowState = .failed
            return
        }

        do {
            mediaPlayback.pauseForDictation()
            dictationOverlay.showListening()
            let recordingURL = try recorder.startRecording()
            lastRecordingURL = recordingURL
            workflowState = .recording
            errorMessage = nil
            statusMessage = insertAfterTranscription ? "Listening. Release the shortcut to insert." : "Recording to \(recordingURL.lastPathComponent)…"
            modelLogger.notice("Recording started at \(recordingURL.path, privacy: .public)")
        } catch {
            dictationOverlay.hide()
            mediaPlayback.resumePausedMedia()
            insertAfterCurrentDictation = false
            insertionTargetApplication = nil
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Recording could not be started."
        }
    }

    func stopDictation() async {
        guard canStopDictation else { return }
        let shouldInsert = insertAfterCurrentDictation
        insertAfterCurrentDictation = false

        guard let recordingURL = recorder.stopRecording() else {
            dictationOverlay.hide()
            mediaPlayback.resumePausedMedia()
            workflowState = .failed
            errorMessage = "No recording file was available to transcribe."
            return
        }

        dictationOverlay.showTranscribing()
        let didTranscribe = await transcribeAudioFile(at: recordingURL, statusPrefix: "Transcribing recording")
        if didTranscribe, shouldInsert {
            await insertLatestTranscriptIntoTargetApplication()
        } else {
            dictationOverlay.hide()
        }
        mediaPlayback.resumePausedMedia()
        insertionTargetApplication = nil
    }

    func copyLatestTranscript() {
        guard !latestTranscript.isEmpty else { return }
        copyTextToPasteboard(latestTranscript)
        dictationOverlay.showCopied()
        statusMessage = "Transcript copied."
    }

    func saveLatestTranscriptAsClip() {
        guard !latestTranscript.isEmpty else { return }
        saveClipboardClip(text: latestTranscript, source: "Saved from latest transcript")
        statusMessage = "Saved latest transcript to Clipboard."
    }

    func copyTranscriptText(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        copyTextToPasteboard(text)
        dictationOverlay.showCopied()
        statusMessage = "Transcript copied."
    }

    func saveTranscriptTextAsClip(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        saveClipboardClip(text: text, source: "Saved from history")
        statusMessage = "Saved transcript to Clipboard."
    }

    func insertLatestTranscript() {
        guard !latestTranscript.isEmpty else { return }

        do {
            textInsertion.copyToPasteboard(latestTranscript)
            markPasteboardChangeAsHandled()
            try textInsertion.insertFromPasteboard()
            dictationOverlay.showPasted()
            statusMessage = "Transcript pasted."
        } catch {
            dictationOverlay.hide()
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Insertion could not be completed."
        }
    }

    private func insertLatestTranscriptIntoTargetApplication() async {
        guard !latestTranscript.isEmpty else {
            dictationOverlay.hide()
            return
        }

        do {
            textInsertion.copyToPasteboard(latestTranscript)
            markPasteboardChangeAsHandled()

            if let insertionTargetApplication {
                insertionTargetApplication.activate()
                try? await Task.sleep(for: .milliseconds(220))
            }

            try textInsertion.insertFromPasteboard()
            dictationOverlay.showPasted()
            statusMessage = "Transcript pasted."
        } catch {
            dictationOverlay.hide()
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Insertion could not be completed."
        }
    }

    func updateSelectedModel(_ model: LocalModel) {
        selectedModel = model
        latestTranscript = latestTranscript
        refreshEnvironment()
        statusMessage = isModelInstalled(model)
            ? "Default model: \(model.displayName)"
            : "Default model set to \(model.displayName). Download it in Models to use it."
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

    @discardableResult
    private func transcribeAudioFile(at audioURL: URL, statusPrefix: String) async -> Bool {
        if !modelIsAvailable {
            await prepareModelIfNeeded()
        }

        guard modelIsAvailable else {
            workflowState = .failed
            return false
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

            guard isUsefulTranscript(result.text) else {
                try? FileManager.default.removeItem(at: result.transcriptFileURL)
                workflowState = .ready
                errorMessage = nil
                latestTranscript = ""
                lastTranscriptFileURL = nil
                statusMessage = "No speech detected."
                modelLogger.notice("Transcription produced no speech")
                return false
            }

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
            return true
        } catch {
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Transcription failed."
            return false
        }
    }

    func selectTranscript(_ record: TranscriptRecord) {
        selectedTranscriptRecordID = record.id
        latestTranscript = record.text
        lastRecordingURL = record.audioFileURL
        lastTranscriptFileURL = record.transcriptFileURL
        selectedSidebarItem = .history
        statusMessage = "Transcript selected."
    }

    func revealTranscriptInFinder(_ record: TranscriptRecord) {
        NSWorkspace.shared.activateFileViewerSelecting([record.transcriptFileURL])
    }

    func openTranscriptFile(_ record: TranscriptRecord) {
        NSWorkspace.shared.open(record.transcriptFileURL)
    }

    func openTranscriptRecording(_ record: TranscriptRecord) {
        guard let audioFileURL = record.audioFileURL,
              FileManager.default.fileExists(atPath: audioFileURL.path) else { return }
        NSWorkspace.shared.open(audioFileURL)
    }

    @discardableResult
    func saveTranscript(_ record: TranscriptRecord, text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            workflowState = .failed
            errorMessage = "Transcript text cannot be empty."
            statusMessage = "Transcript was not saved."
            return false
        }

        do {
            try text.write(to: record.transcriptFileURL, atomically: true, encoding: .utf8)
            guard let index = transcriptHistory.firstIndex(where: { $0.id == record.id }) else { return false }
            transcriptHistory[index].text = text

            if selectedTranscriptRecordID == record.id {
                latestTranscript = text
                lastTranscriptFileURL = record.transcriptFileURL
                lastRecordingURL = record.audioFileURL
            }

            errorMessage = nil
            statusMessage = "Transcript saved."
            return true
        } catch {
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Transcript could not be saved."
            return false
        }
    }

    func copyTranscript(_ record: TranscriptRecord) {
        copyTextToPasteboard(record.text)
        dictationOverlay.showCopied()
        statusMessage = "Transcript copied."
    }

    func insertTranscript(_ record: TranscriptRecord) {
        do {
            textInsertion.copyToPasteboard(record.text)
            markPasteboardChangeAsHandled()
            try textInsertion.insertFromPasteboard()
            dictationOverlay.showPasted()
            statusMessage = "Transcript pasted."
        } catch {
            dictationOverlay.hide()
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

    func selectClipboardClip(_ clip: ClipboardClip) {
        selectedClipboardClipID = clip.id
        selectedSidebarItem = .clipboard
        statusMessage = "Selected clip from \(clip.createdAt.formatted(date: .abbreviated, time: .shortened))."
    }

    func copyClipboardClip(_ clip: ClipboardClip) {
        textInsertion.copyToPasteboard(clip.text)
        markPasteboardChangeAsHandled()
        selectedClipboardClipID = clip.id
        dictationOverlay.showCopied()
        statusMessage = "Clip copied."
    }

    func insertClipboardClip(_ clip: ClipboardClip) {
        do {
            textInsertion.copyToPasteboard(clip.text)
            markPasteboardChangeAsHandled()
            selectedClipboardClipID = clip.id
            try textInsertion.insertFromPasteboard()
            dictationOverlay.showPasted()
            statusMessage = "Clip pasted."
        } catch {
            dictationOverlay.hide()
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Insertion could not be completed."
        }
    }

    func deleteClipboardClip(_ clip: ClipboardClip) {
        clipboardClips.removeAll { $0.id == clip.id }
        if selectedClipboardClipID == clip.id {
            selectedClipboardClipID = clipboardClips.first?.id
        }
        persistClipboardClips()
        statusMessage = "Clip deleted."
    }

    func clearClipboardClips() {
        clipboardClips.removeAll()
        selectedClipboardClipID = nil
        persistClipboardClips()
        statusMessage = "Clipboard clips cleared."
    }

    func revealTranscriptFolder() {
        NSWorkspace.shared.open(AppPaths.transcriptsDirectory)
    }

    func revealModelInFinder(_ model: LocalModel? = nil) {
        let targetModel = model ?? selectedModel
        guard isModelInstalled(targetModel) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([targetModel.localURL])
    }

    func openModelsFolder() {
        NSWorkspace.shared.open(AppPaths.modelsDirectory)
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
                guard isUsefulTranscript(text) else {
                    try? FileManager.default.removeItem(at: url)
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

    private func copyTextToPasteboard(_ text: String) {
        textInsertion.copyToPasteboard(text)
        markPasteboardChangeAsHandled()
    }

    private func saveClipboardClip(text: String, source: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, isUsefulClipboardText(trimmedText) else { return }

        clipboardClips.removeAll { $0.text == text }
        let clip = ClipboardClip(text: text, source: source)
        clipboardClips.insert(clip, at: 0)
        if clipboardClips.count > 5 {
            clipboardClips = Array(clipboardClips.prefix(5))
        }
        selectedClipboardClipID = clip.id
        persistClipboardClips()
    }

    private func isUsefulTranscript(_ text: String) -> Bool {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else { return false }

        let emptyMarkers: Set<String> = [
            "[blank_audio]",
            "[blank audio]",
            "(blank_audio)",
            "(blank audio)",
            "blank_audio",
            "blank audio"
        ]
        return !emptyMarkers.contains(normalized)
    }

    private func isUsefulClipboardText(_ text: String) -> Bool {
        isUsefulTranscript(text)
    }

    private func isUserCopiedClip(_ clip: ClipboardClip) -> Bool {
        guard isUsefulClipboardText(clip.text) else { return false }

        let wispTranscriptSources = [
            "Latest transcript",
            "Inserted transcript",
            "History transcript",
            "System pasteboard"
        ]
        if wispTranscriptSources.contains(clip.source) {
            return false
        }

        return !clip.source.hasPrefix("Transcript from ")
    }

    private func startPasteboardMonitoring() {
        pasteboardMonitorTimer?.invalidate()
        lastObservedPasteboardChangeCount = textInsertion.pasteboardChangeCount
        pasteboardMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.captureExternalPasteboardChangeIfNeeded()
            }
        }
    }

    private func stopPasteboardMonitoring() {
        pasteboardMonitorTimer?.invalidate()
        pasteboardMonitorTimer = nil
        lastObservedPasteboardChangeCount = textInsertion.pasteboardChangeCount
    }

    private func captureExternalPasteboardChangeIfNeeded() {
        guard rememberCopiedText else { return }

        let changeCount = textInsertion.pasteboardChangeCount
        guard changeCount != lastObservedPasteboardChangeCount else { return }

        lastObservedPasteboardChangeCount = changeCount
        guard let text = textInsertion.readPasteboardString(),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        saveClipboardClip(text: text, source: "Copied on this Mac")
    }

    private func markPasteboardChangeAsHandled() {
        lastObservedPasteboardChangeCount = textInsertion.pasteboardChangeCount
    }

    private func currentInsertionTargetApplication() -> NSRunningApplication? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.bundleIdentifier != AppPaths.bundleIdentifier else {
            return nil
        }

        return app
    }

    private func loadClipboardClipsFromDisk() {
        do {
            try AppPaths.ensureDirectories()
            guard FileManager.default.fileExists(atPath: AppPaths.clipboardClipsURL.path) else {
                return
            }

            let data = try Data(contentsOf: AppPaths.clipboardClipsURL)
            let loadedClips = try JSONDecoder().decode([ClipboardClip].self, from: data)
            clipboardClips = Array(loadedClips.filter { isUserCopiedClip($0) }.prefix(5))
            selectedClipboardClipID = clipboardClips.first?.id
            persistClipboardClips()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persistClipboardClips() {
        do {
            try AppPaths.ensureDirectories()
            let data = try JSONEncoder().encode(clipboardClips)
            try data.write(to: AppPaths.clipboardClipsURL, options: .atomic)
        } catch {
            workflowState = .failed
            errorMessage = error.localizedDescription
            statusMessage = "Clipboard clips could not be saved."
        }
    }

    private func modelFileSize(for model: LocalModel) -> Int64 {
        guard isModelInstalled(model),
              let values = try? model.localURL.resourceValues(forKeys: [.fileSizeKey]),
              let fileSize = values.fileSize else {
            return 0
        }

        return Int64(fileSize)
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
