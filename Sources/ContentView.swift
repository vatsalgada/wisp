import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var appModel: AppModel
    private let chromeClearance: CGFloat = 150

    var body: some View {
        HSplitView {
            SidebarView(appModel: appModel, chromeClearance: chromeClearance)
                .frame(minWidth: 220, idealWidth: 248, maxWidth: 280)

            ZStack {
                AppChromeBackground()

                VStack(alignment: .leading, spacing: 0) {
                    DetailHeader(appModel: appModel)
                        .padding(.horizontal, 28)
                        .padding(.top, chromeClearance)
                        .padding(.bottom, 20)

                    detailContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .tint(WispPalette.accent)
        .task {
            appModel.refreshEnvironment()
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch appModel.selectedSidebarItem ?? .capture {
        case .capture:
            DetailScrollView {
                CaptureDashboard(appModel: appModel)
            }
        case .history:
            DetailScrollView {
                HistoryView(appModel: appModel)
            }
        case .models:
            DetailScrollView {
                ModelsView(appModel: appModel)
            }
        case .permissions:
            DetailScrollView {
                PermissionsView(appModel: appModel)
            }
        case .settings:
            DetailScrollView {
                SettingsPageView(appModel: appModel)
            }
        }
    }
}

private struct DetailScrollView<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct SidebarView: View {
    @Bindable var appModel: AppModel
    let chromeClearance: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            sidebarHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        SidebarSectionTitle("Workspace")

                        ForEach(AppModel.SidebarItem.allCases) { item in
                            SidebarButton(
                                title: item.title,
                                symbolName: item.symbolName,
                                isSelected: appModel.selectedSidebarItem == item
                            ) {
                                appModel.selectedSidebarItem = item
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SidebarSectionTitle("Quick Actions")

                        SidebarActionRow(
                            title: "Prepare model",
                            subtitle: appModel.modelIsAvailable ? "Cached and ready offline" : "Download for offline use",
                            symbolName: "arrow.down.circle"
                        ) {
                            Task {
                                await appModel.prepareModelIfNeeded()
                            }
                        }

                        SidebarActionRow(
                            title: "Transcribe a file",
                            subtitle: "Import audio from disk",
                            symbolName: "waveform.and.magnifyingglass"
                        ) {
                            Task {
                                await appModel.transcribeFromOpenPanel()
                            }
                        }

                        SidebarActionRow(
                            title: "Open settings",
                            subtitle: "Tune defaults and behavior",
                            symbolName: "gearshape"
                        ) {
                            appModel.selectedSidebarItem = .settings
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SidebarSectionTitle("Current model")

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appModel.selectedModel.displayName)
                                        .font(.headline)
                                        .foregroundStyle(WispPalette.ink)
                                    Text(appModel.selectedModel.recommendedLabel.capitalized)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(WispPalette.muted)
                                }
                                Spacer()
                                Image(systemName: "cpu")
                                    .foregroundStyle(WispPalette.muted)
                            }

                            Text(appModel.selectedModel.summary)
                                .font(.caption)
                                .foregroundStyle(WispPalette.muted)
                                .lineLimit(3)
                        }
                    }
                    .padding(15)
                    .panelBackground(prominent: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, 20)
        .padding(.top, chromeClearance)
        .padding(.bottom, 20)
        .background(SidebarBackground())
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    WispPalette.accent,
                                    WispPalette.accentStrong
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)

                    Image(systemName: "waveform")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wisp")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(WispPalette.ink)
                    Text("Local dictation studio")
                        .font(.subheadline)
                        .foregroundStyle(WispPalette.muted)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                StatusDot(color: appModel.isDictating ? .red : .green)
                Text(appModel.isDictating ? "Recording live" : "Ready for capture")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WispPalette.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(WispPalette.subtlePanelTop, in: Capsule())
        }
    }
}

private struct DetailHeader: View {
    @Bindable var appModel: AppModel

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                headerCopy
                Spacer()
                HeaderAccessoryGroup(appModel: appModel)
            }

            VStack(alignment: .leading, spacing: 14) {
                headerCopy

                ScrollView(.horizontal, showsIndicators: false) {
                    HeaderAccessoryGroup(appModel: appModel)
                }
            }
        }
    }

    private var headerCopy: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appModel.selectedSidebarItem?.title ?? "Capture")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(WispPalette.ink)
            Text(headerSubtitle)
                .foregroundStyle(WispPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var headerSubtitle: String {
        switch appModel.selectedSidebarItem ?? .capture {
        case .capture:
            return "Bundled runtime, local model cache, and a workspace that feels native on macOS."
        case .history:
            return "Browse recent transcripts, reload prior sessions, and move between saved dictation artifacts."
        case .models:
            return "The runtime ships in the app bundle, while Wisp downloads and caches whichever local speech model you choose."
        case .permissions:
            return "Keep microphone and accessibility access healthy so recording and insertion stay reliable."
        case .settings:
            return "Choose appearance, launch behavior, and dictation defaults from a dedicated settings workspace."
        }
    }
}

private struct CaptureDashboard: View {
    @Bindable var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HeroPanel(appModel: appModel)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 16)], spacing: 16) {
                StatusCard(title: "Workflow", value: appModel.workflowState.displayName, symbolName: "waveform")
                StatusCard(title: "Model", value: appModel.selectedModel.displayName, symbolName: "cpu")
                StatusCard(title: "Mic", value: appModel.microphonePermission.displayName, symbolName: "mic.fill")
                StatusCard(title: "History", value: "\(appModel.transcriptHistory.count) local items", symbolName: "clock.arrow.circlepath")
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    sessionStatusPanel
                    controlsPanel
                        .frame(width: 360, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 18) {
                    sessionStatusPanel
                    controlsPanel
                }
            }
            .padding(20)
            .panelBackground()

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    transcriptPanel
                    artifactsPanel
                        .frame(width: 320)
                }

                VStack(alignment: .leading, spacing: 18) {
                    transcriptPanel
                    artifactsPanel
                }
            }
            .padding(20)
            .panelBackground()

            if !appModel.transcriptHistory.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        SectionHeader(
                            title: "Recent transcripts",
                            subtitle: "Jump back into your latest on-device sessions."
                        )
                        Spacer()
                        Button("Open history") {
                            appModel.selectedSidebarItem = .history
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
                        ForEach(Array(appModel.transcriptHistory.prefix(4))) { record in
                            Button {
                                appModel.selectTranscript(record)
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(WispPalette.muted)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .foregroundStyle(WispPalette.muted)
                                    }

                                    Text(record.text)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(3)
                                }
                                .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
                                .padding(16)
                                .background(
                                    Color.white.opacity(0.78),
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(.white.opacity(0.58), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
                .panelBackground()
            }
        }
    }

    private var sessionStatusPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Session status",
                subtitle: "Everything in this flow is designed to stay local and resilient across relaunches."
            )

            Text(appModel.statusMessage)
                .font(.title3.weight(.medium))
                .foregroundStyle(WispPalette.ink)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    metadataPills
                }

                VStack(alignment: .leading, spacing: 10) {
                    metadataPills
                }
            }

            if let errorMessage = appModel.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var metadataPills: some View {
        MetadataPill(
            title: appModel.modelIsAvailable ? "Model cached" : "Model pending",
            symbolName: appModel.modelIsAvailable ? "internaldrive.fill" : "arrow.down.circle"
        )
        MetadataPill(
            title: appModel.accessibilityTrusted ? "Insert enabled" : "Insert setup needed",
            symbolName: "rectangle.on.rectangle"
        )
        MetadataPill(
            title: "\(appModel.latestTranscriptWordCount) words",
            symbolName: "text.word.spacing"
        )
    }

    private var controlsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Controls",
                subtitle: "Record, import, refresh, and open preferences from one compact dock."
            )
            CommandDock(appModel: appModel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    SectionHeader(
                        title: "Transcript",
                        subtitle: "Edit, copy, and insert the latest capture."
                    )
                    Spacer()
                    transcriptActions
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        title: "Transcript",
                        subtitle: "Edit, copy, and insert the latest capture."
                    )
                    transcriptActions
                }
            }

            TextEditor(text: $appModel.latestTranscript)
                .font(.body)
                .frame(minHeight: 320)
                .padding(14)
                .background(
                    Color.white.opacity(0.97),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )

            if appModel.latestTranscript.isEmpty {
                EmptyStateBanner(
                    title: "Nothing captured yet",
                    subtitle: "Start recording from here or the menu bar to populate this workspace."
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var transcriptActions: some View {
        HStack(spacing: 10) {
            Button("Copy") {
                appModel.copyLatestTranscript()
            }
            .disabled(appModel.latestTranscript.isEmpty)

            Button("Insert") {
                appModel.insertLatestTranscript()
            }
            .disabled(appModel.latestTranscript.isEmpty)
        }
    }

    private var artifactsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Artifacts",
                subtitle: "Quick access to the files Wisp most recently created."
            )

            ArtifactCard(title: "Latest recording", url: appModel.lastRecordingURL)
            ArtifactCard(title: "Latest transcript", url: appModel.lastTranscriptFileURL)

            if let selectedRecord = appModel.selectedTranscriptRecord {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected history item")
                        .font(.headline)
                    Text(selectedRecord.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(WispPalette.muted)
                    Text(selectedRecord.text)
                        .font(.subheadline)
                        .foregroundStyle(WispPalette.muted)
                        .lineLimit(4)
                }
                .padding(18)
                .panelBackground(prominent: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HistoryView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "History",
                subtitle: "Local transcripts survive relaunches, so Wisp keeps building value outside the live recording flow."
            )

            if appModel.transcriptHistory.isEmpty {
                EmptyStateBanner(
                    title: "No transcripts yet",
                    subtitle: "Record or transcribe a file to start building local history."
                )
                .panelBackground()
            } else {
                historyToolbar

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        historyListPanel
                            .frame(width: 340)
                        historyDetailPanel
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        historyListPanel
                        historyDetailPanel
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var historyToolbar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                HistorySearchField(text: $appModel.historySearchText)
                Button("Open Folder") {
                    appModel.revealTranscriptFolder()
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                HistorySearchField(text: $appModel.historySearchText)
                Button("Open Folder") {
                    appModel.revealTranscriptFolder()
                }
            }
        }
    }

    private var historyListPanel: some View {
        ScrollView {
            if appModel.filteredTranscriptHistory.isEmpty {
                EmptyStateBanner(
                    title: "No matching transcripts",
                    subtitle: "Try a different search term or clear the filter to see your full local history."
                )
                .padding(.top, 2)
            } else {
                VStack(spacing: 12) {
                    ForEach(appModel.filteredTranscriptHistory) { record in
                        HistoryRow(
                            record: record,
                            isSelected: appModel.selectedTranscriptRecordID == record.id
                        ) {
                            appModel.selectTranscript(record)
                        }
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 460, alignment: .top)
        .padding(10)
        .panelBackground()
    }

    private var historyDetailPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let selectedRecord = appModel.selectedTranscriptRecord {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top) {
                        historyDetailHeader(for: selectedRecord)
                        Spacer()
                        historyDetailActions(for: selectedRecord)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        historyDetailHeader(for: selectedRecord)
                        historyDetailActions(for: selectedRecord)
                    }
                }

                TextEditor(text: Binding(
                    get: { selectedRecord.text },
                    set: { _ in }
                ))
                .font(.body)
                .frame(maxWidth: .infinity, minHeight: 360, alignment: .topLeading)
                .padding(14)
                .background(
                    Color.white.opacity(0.97),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )

                HStack {
                    Button(role: .destructive) {
                        appModel.deleteTranscript(selectedRecord)
                    } label: {
                        Text("Delete Transcript")
                    }
                    Spacer()
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .panelBackground()
    }

    private func historyDetailHeader(for selectedRecord: AppModel.TranscriptRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(selectedRecord.createdAt.formatted(date: .complete, time: .shortened))
                .font(.headline)
                .foregroundStyle(WispPalette.ink)
            Text("Saved locally in your transcript archive")
                .foregroundStyle(WispPalette.muted)
        }
    }

    private func historyDetailActions(for selectedRecord: AppModel.TranscriptRecord) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                historyActionButtons(for: selectedRecord)
            }

            VStack(alignment: .leading, spacing: 10) {
                historyActionButtons(for: selectedRecord)
            }
        }
    }

    @ViewBuilder
    private func historyActionButtons(for selectedRecord: AppModel.TranscriptRecord) -> some View {
        Button("Copy") {
            appModel.copyTranscript(selectedRecord)
        }

        Button("Insert") {
            appModel.insertTranscript(selectedRecord)
        }

        Button("Reveal in Finder") {
            appModel.revealTranscriptInFinder(selectedRecord)
        }

        Button("Open File") {
            appModel.openTranscriptFile(selectedRecord)
        }
    }
}

private struct ModelsView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Models",
                subtitle: "The runtime ships in the app bundle, while Wisp downloads and caches whichever local speech model you choose."
            )

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    modelHighlights
                }

                VStack(spacing: 16) {
                    modelHighlights
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 16)], spacing: 16) {
                ForEach(LocalModel.allCases) { model in
                    ModelOptionCard(
                        model: model,
                        isSelected: appModel.selectedModel == model,
                        isCached: FileManager.default.fileExists(atPath: model.localURL.path)
                    ) {
                        appModel.updateSelectedModel(model)
                    }
                }
            }

            HStack {
                Button("Download Selected Model") {
                    Task {
                        await appModel.prepareModelIfNeeded()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Reveal Cached Model") {
                    appModel.revealModelInFinder()
                }
                .disabled(!appModel.modelIsAvailable)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("Model cached") {
                    Text(appModel.modelIsAvailable ? "Yes" : "No")
                }
                LabeledContent("Approximate size") {
                    Text(appModel.selectedModel.approximateSize)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Model path") {
                    Text(appModel.modelPath.isEmpty ? "Not downloaded yet" : appModel.modelPath)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(20)
            .panelBackground()
        }
    }
}

private struct PermissionsView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Permissions",
                subtitle: "A small amount of setup unlocks live capture and one-click insertion into the active app."
            )

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    permissionCards
                }

                VStack(spacing: 18) {
                    permissionCards
                }
            }

            HighlightPanel(
                title: "Permission health",
                subtitle: "If a system prompt appears, grant access once and the app will remember it. The microphone-permission crash path has already been patched in this build.",
                symbolName: "checkmark.shield.fill"
            )
        }
    }

    @ViewBuilder
    private var permissionCards: some View {
        PermissionRow(
            title: "Microphone",
            value: appModel.microphonePermission.displayName,
            detail: appModel.microphonePermission.detailText,
            actionTitle: "Request Microphone",
            secondaryActionTitle: "Open Settings",
            symbolName: "mic.fill"
        ) {
            Task {
                await appModel.requestMicrophoneAccess()
            }
        } secondaryAction: {
            appModel.openMicrophoneSettings()
        }

        PermissionRow(
            title: "Accessibility",
            value: appModel.accessibilityTrusted ? "Granted" : "Required",
            detail: appModel.accessibilityTrusted
                ? "Wisp can paste the latest transcript into the frontmost app when you choose Insert."
                : "Turn this on to enable best-effort insertion into the active application.",
            actionTitle: "Open Accessibility Prompt",
            secondaryActionTitle: "System Settings",
            symbolName: "rectangle.on.rectangle"
        ) {
            appModel.requestAccessibilityAccess()
        } secondaryAction: {
            appModel.openAccessibilitySettings()
        }
    }
}

private extension ModelsView {
    @ViewBuilder
    var modelHighlights: some View {
        HighlightPanel(
            title: "Bundled runtime",
            subtitle: "Another Mac does not need a separate Whisper install. Wisp carries the engine and manages the model cache itself.",
            symbolName: "shippingbox.fill"
        )

        HighlightPanel(
            title: "Current default",
            subtitle: "\(appModel.selectedModel.displayName) is tuned for \(appModel.selectedModel.recommendedLabel) local dictation.",
            symbolName: "cpu.fill"
        )
    }
}

private struct HeaderSearchField: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
            Text("Fully local workflow")
                .foregroundStyle(WispPalette.muted)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(minWidth: 190, alignment: .leading)
        .background(WispPalette.subtlePanelTop, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(WispPalette.panelStroke, lineWidth: 1)
        )
    }
}

private struct HistorySearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search transcripts", text: $text)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(minWidth: 280, alignment: .leading)
        .background(WispPalette.subtlePanelTop, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(WispPalette.panelStroke, lineWidth: 1)
        )
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(WispPalette.ink)
            Text(subtitle)
                .foregroundStyle(WispPalette.muted)
        }
    }
}

private struct SidebarSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(WispPalette.muted)
            .textCase(.uppercase)
            .padding(.horizontal, 10)
    }
}

private struct MetadataPill: View {
    let title: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(WispPalette.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(WispPalette.subtlePanelTop, in: Capsule())
    }
}

private struct EmptyStateBanner: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(WispPalette.ink)
            Text(subtitle)
                .foregroundStyle(WispPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(WispPalette.subtlePanelTop, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct HighlightPanel: View {
    let title: String
    let subtitle: String
    let symbolName: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbolName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.27, green: 0.53, blue: 0.94),
                            Color(red: 0.36, green: 0.78, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(WispPalette.ink)
                Text(subtitle)
                    .foregroundStyle(WispPalette.muted)
            }

            Spacer()
        }
        .padding(18)
        .panelBackground()
    }
}

private struct HistoryRow: View {
    let record: AppModel.TranscriptRecord
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WispPalette.muted)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "arrow.right.circle")
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }

                Text(record.text)
                    .foregroundStyle(WispPalette.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [
                            WispPalette.accent.opacity(0.18),
                            WispPalette.accentWash.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [WispPalette.panelTop, WispPalette.subtlePanelBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? WispPalette.accent.opacity(0.34) : WispPalette.panelStroke, lineWidth: 1)
            )
            .shadow(color: isHovered ? WispPalette.shadow.opacity(0.65) : .clear, radius: 18, x: 0, y: 10)
            .scaleEffect(isHovered ? 1.01 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                isHovered = hovering
            }
        }
    }
}

private struct HeaderPill: View {
    let title: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
            Text(title)
        }
        .font(.subheadline.weight(.medium))
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.82), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.62), lineWidth: 1))
    }
}

private struct HeaderAccessoryGroup: View {
    @Bindable var appModel: AppModel

    var body: some View {
        HStack(spacing: 10) {
            HeaderSearchField()
            HeaderPill(title: "\(appModel.transcriptHistory.count) sessions", symbolName: "clock.arrow.circlepath")
            HeaderPill(title: appModel.selectedModel.displayName, symbolName: "cpu")
            HeaderPill(title: appModel.hotkey, symbolName: "command")
        }
    }
}

private struct SidebarButton: View {
    let title: String
    let symbolName: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : WispPalette.ink)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [
                            WispPalette.accent,
                            WispPalette.accentStrong
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [Color.clear, Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? Color.white.opacity(0.18) : Color.clear,
                        lineWidth: 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(isSelected ? .white : .primary)
            .shadow(color: isSelected || isHovered ? WispPalette.shadow.opacity(0.45) : .clear, radius: 16, x: 0, y: 10)
            .scaleEffect(isHovered ? 1.01 : 1)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
                isHovered = hovering
            }
        }
    }
}

private struct SidebarActionRow: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbolName)
                    .frame(width: 18)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WispPalette.ink)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(WispPalette.muted)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(WispPalette.subtlePanelTop, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isHovered ? WispPalette.panelStroke.opacity(1.2) : .clear, lineWidth: 1)
            )
            .shadow(color: isHovered ? WispPalette.shadow.opacity(0.45) : .clear, radius: 14, x: 0, y: 8)
            .scaleEffect(isHovered ? 1.01 : 1)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
                isHovered = hovering
            }
        }
    }
}

private struct PermissionRow: View {
    let title: String
    let value: String
    let detail: String
    let actionTitle: String
    let secondaryActionTitle: String?
    let symbolName: String
    let action: () -> Void
    let secondaryAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: symbolName)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [
                                WispPalette.accent,
                                WispPalette.accentStrong
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                    )

                Spacer()

                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WispPalette.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(WispPalette.subtlePanelTop, in: Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(WispPalette.ink)
                Text(detail)
                    .foregroundStyle(WispPalette.muted)
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Button(actionTitle, action: action)

                if let secondaryActionTitle,
                   let secondaryAction {
                    Button(secondaryActionTitle, action: secondaryAction)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .padding(20)
        .panelBackground()
    }
}

private struct ArtifactCard: View {
    let title: String
    let url: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(WispPalette.ink)
                Spacer()
                if url != nil {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(WispPalette.muted)
                }
            }

            Text(url?.path ?? "Not available yet")
                .font(.caption)
                .foregroundStyle(WispPalette.muted)
                .lineLimit(3)

            if let url {
                Button("Open") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .panelBackground(prominent: false)
    }
}

private struct StatusCard: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(WispPalette.accentSoft)
                    .frame(width: 44, height: 44)

                Image(systemName: symbolName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(WispPalette.accent)
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(WispPalette.ink)

            Text(value)
                .font(.body)
                .foregroundStyle(WispPalette.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .panelBackground()
    }
}

private struct CommandDock: View {
    @Bindable var appModel: AppModel

    var body: some View {
        HStack(spacing: 12) {
            DockButton(
                title: appModel.isDictating ? "Stop" : "Record",
                symbolName: appModel.isDictating ? "stop.fill" : "mic.fill",
                prominent: true
            ) {
                Task {
                    await appModel.toggleDictation()
                }
            }

            DockButton(title: "Import", symbolName: "waveform.and.magnifyingglass") {
                Task {
                    await appModel.transcribeFromOpenPanel()
                }
            }

            DockButton(title: "Refresh", symbolName: "arrow.clockwise") {
                appModel.refreshEnvironment()
            }

            DockButton(title: "Settings", symbolName: "gearshape") {
                appModel.selectedSidebarItem = .settings
            }
        }
        .padding(12)
        .background(WispPalette.subtlePanelTop, in: Capsule())
        .overlay(Capsule().stroke(WispPalette.panelStroke, lineWidth: 1))
    }
}

private struct DockButton: View {
    let title: String
    let symbolName: String
    var prominent = false
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(
                        prominent
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        WispPalette.accent,
                                        WispPalette.accentStrong
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(WispPalette.subtlePanelTop),
                        in: Circle()
                    )
                    .foregroundStyle(prominent ? .white : .primary)

                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WispPalette.ink)
            }
            .frame(width: 76, height: 82)
            .scaleEffect(isHovered ? 1.03 : 1)
            .shadow(color: isHovered ? WispPalette.shadow.opacity(0.45) : .clear, radius: 16, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                isHovered = hovering
            }
        }
    }
}

private struct ModelOptionCard: View {
    let model: LocalModel
    let isSelected: Bool
    let isCached: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.displayName)
                            .font(.headline)
                            .foregroundStyle(WispPalette.ink)
                        Text(model.recommendedLabel.capitalized)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WispPalette.muted)
                    }

                    Spacer()

                    Image(systemName: isCached ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundStyle(isCached ? .green : .secondary)
                }

                Text(model.summary)
                    .font(.subheadline)
                    .foregroundStyle(WispPalette.muted)
                    .lineLimit(3)

                HStack {
                    Text(model.approximateSize)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WispPalette.muted)
                    Spacer()
                    Text(isCached ? "Cached" : "Downloadable")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WispPalette.muted)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
            .padding(18)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [
                            WispPalette.accent.opacity(0.18),
                            WispPalette.accentWash.opacity(0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [WispPalette.panelTop, WispPalette.panelBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? WispPalette.accent.opacity(0.45) : WispPalette.panelStroke, lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.01 : 1)
            .shadow(color: isHovered ? WispPalette.shadow.opacity(0.55) : .clear, radius: 18, x: 0, y: 12)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                isHovered = hovering
            }
        }
    }
}

private struct StatusDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

private struct HeroPanel: View {
    @Bindable var appModel: AppModel

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 24) {
                heroLead
                heroMetrics
                    .frame(width: 260)
            }

            VStack(alignment: .leading, spacing: 24) {
                heroLead
                heroMetrics
            }
        }
        .padding(30)
        .background(
            LinearGradient(
                colors: [
                    WispPalette.heroTop,
                    WispPalette.heroBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(WispPalette.heroStroke, lineWidth: 1)
        )
        .shadow(color: WispPalette.shadow.opacity(0.9), radius: 34, x: 0, y: 22)
    }

    private var heroLead: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    HeroTag(title: "Bundled runtime")
                    HeroTag(title: "Local models")
                    HeroTag(title: "Menu bar ready")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Wisp")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Fast local dictation for macOS, shaped like a polished desktop workspace and powered entirely on-device.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    heroButtons
                }

                VStack(alignment: .leading, spacing: 12) {
                    heroButtons
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var heroButtons: some View {
        HeroActionButton(
            title: appModel.isDictating ? "Stop Recording" : "Start Recording",
            prominent: true
        ) {
            Task {
                await appModel.toggleDictation()
            }
        }

        HeroActionButton(title: "Transcribe File…") {
            Task {
                await appModel.transcribeFromOpenPanel()
            }
        }

        HeroActionButton(title: "Prepare Model") {
            Task {
                await appModel.prepareModelIfNeeded()
            }
        }
    }

    private var heroMetrics: some View {
        VStack(alignment: .leading, spacing: 14) {
            HeroMetricCard(
                title: appModel.workflowState.displayName,
                subtitle: "Current workflow state",
                symbolName: "sparkles"
            )
            HeroMetricCard(
                title: appModel.modelIsAvailable ? "Offline ready" : "Needs model",
                subtitle: appModel.selectedModel.displayName,
                symbolName: "internaldrive"
            )
            HeroMetricCard(
                title: appModel.microphonePermission.displayName,
                subtitle: "Microphone permission",
                symbolName: "mic"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HeroTag: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(WispPalette.heroTag, in: Capsule())
            .foregroundStyle(.white.opacity(0.86))
    }
}

private struct HeroActionButton: View {
    let title: String
    var prominent = false
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(prominent ? .white : .white.opacity(0.92))
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(minWidth: 150)
                .background(
                    prominent
                        ? LinearGradient(
                            colors: [
                                WispPalette.accent,
                                WispPalette.accentStrong
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                WispPalette.heroCard,
                                WispPalette.heroCard.opacity(0.82)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(WispPalette.heroStroke.opacity(prominent ? 0.0 : 1.0), lineWidth: 1)
                )
                .scaleEffect(isHovered ? 1.02 : 1)
                .shadow(color: isHovered ? WispPalette.shadow.opacity(0.45) : .clear, radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                isHovered = hovering
            }
        }
    }
}

private struct HeroMetricCard: View {
    let title: String
    let subtitle: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(WispPalette.heroTag, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.70))
            }

            Spacer()
        }
        .padding(14)
        .background(WispPalette.heroCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct AppChromeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    WispPalette.canvasTop,
                    WispPalette.canvasBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(WispPalette.glowPrimary)
                .frame(width: 520, height: 520)
                .blur(radius: 56)
                .offset(x: 320, y: -260)

            Circle()
                .fill(WispPalette.glowSecondary)
                .frame(width: 460, height: 460)
                .blur(radius: 52)
                .offset(x: -320, y: 260)

            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(WispPalette.frost)
                .padding(18)
                .blur(radius: 36)
        }
        .ignoresSafeArea()
    }
}

private struct SidebarBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                WispPalette.sidebarTop,
                WispPalette.sidebarBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

extension View {
    func panelBackground(prominent: Bool = true) -> some View {
        self
            .background(
                LinearGradient(
                    colors: [
                        prominent ? WispPalette.panelTop : WispPalette.subtlePanelTop,
                        prominent ? WispPalette.panelBottom : WispPalette.subtlePanelBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(WispPalette.panelStroke, lineWidth: 1)
            )
            .shadow(color: WispPalette.shadow, radius: 18, x: 0, y: 12)
    }
}

enum WispPalette {
    static let ink = dynamic(light: (0.13, 0.11, 0.10), dark: (0.95, 0.93, 0.90))
    static let muted = dynamic(light: (0.43, 0.39, 0.36), dark: (0.68, 0.64, 0.60))
    static let accent = dynamic(light: (0.91, 0.39, 0.15), dark: (0.98, 0.56, 0.28))
    static let accentStrong = dynamic(light: (0.72, 0.25, 0.08), dark: (0.95, 0.47, 0.19))
    static let accentSoft = dynamic(light: (0.99, 0.92, 0.87), dark: (0.33, 0.20, 0.13))
    static let accentWash = dynamic(light: (0.98, 0.84, 0.75), dark: (0.45, 0.25, 0.14))

    static let canvasTop = dynamic(light: (0.99, 0.97, 0.94), dark: (0.10, 0.09, 0.08))
    static let canvasBottom = dynamic(light: (0.95, 0.93, 0.90), dark: (0.14, 0.12, 0.11))
    static let sidebarTop = dynamic(light: (0.98, 0.97, 0.95), dark: (0.12, 0.11, 0.10))
    static let sidebarBottom = dynamic(light: (0.95, 0.93, 0.90), dark: (0.10, 0.09, 0.08))
    static let panelTop = dynamic(light: (1.0, 0.995, 0.99), dark: (0.18, 0.16, 0.15))
    static let panelBottom = dynamic(light: (0.96, 0.94, 0.92), dark: (0.15, 0.13, 0.12))
    static let subtlePanelTop = dynamic(light: (0.985, 0.975, 0.965), dark: (0.16, 0.14, 0.13))
    static let subtlePanelBottom = dynamic(light: (0.95, 0.93, 0.91), dark: (0.13, 0.12, 0.11))
    static let panelStroke = dynamic(light: (1.0, 1.0, 1.0, 0.78), dark: (1.0, 1.0, 1.0, 0.08))
    static let shadow = dynamic(light: (0.22, 0.12, 0.06, 0.10), dark: (0.0, 0.0, 0.0, 0.34))

    static let heroTop = dynamic(light: (0.22, 0.14, 0.12), dark: (0.17, 0.12, 0.10))
    static let heroBottom = dynamic(light: (0.36, 0.18, 0.10), dark: (0.27, 0.14, 0.10))
    static let heroCard = dynamic(light: (1.0, 1.0, 1.0, 0.10), dark: (1.0, 1.0, 1.0, 0.08))
    static let heroTag = dynamic(light: (1.0, 1.0, 1.0, 0.12), dark: (1.0, 1.0, 1.0, 0.08))
    static let heroStroke = dynamic(light: (1.0, 1.0, 1.0, 0.10), dark: (1.0, 1.0, 1.0, 0.06))

    static let glowPrimary = dynamic(light: (0.98, 0.74, 0.56, 0.42), dark: (0.93, 0.42, 0.18, 0.18))
    static let glowSecondary = dynamic(light: (0.90, 0.82, 0.70, 0.32), dark: (0.45, 0.28, 0.18, 0.18))
    static let frost = dynamic(light: (1.0, 1.0, 1.0, 0.18), dark: (1.0, 1.0, 1.0, 0.04))

    private static func dynamic(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let useDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let source = useDark ? dark : light
            return NSColor(
                red: source.0,
                green: source.1,
                blue: source.2,
                alpha: 1
            )
        })
    }

    private static func dynamic(
        light: (CGFloat, CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let useDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let source = useDark ? dark : light
            return NSColor(
                red: source.0,
                green: source.1,
                blue: source.2,
                alpha: source.3
            )
        })
    }
}
