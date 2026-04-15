import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        HSplitView {
            SidebarView(appModel: appModel)
                .frame(minWidth: 220, idealWidth: 248, maxWidth: 280)

            ZStack {
                AppChromeBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        DetailHeader(appModel: appModel)

                        Group {
                            switch appModel.selectedSidebarItem ?? .capture {
                            case .capture:
                                CaptureDashboard(appModel: appModel)
                            case .history:
                                HistoryView(appModel: appModel)
                            case .models:
                                ModelsView(appModel: appModel)
                            case .permissions:
                                PermissionsView(appModel: appModel)
                            }
                        }
                    }
                    .padding(28)
                }
            }
        }
        .task {
            appModel.refreshEnvironment()
        }
    }
}

private struct SidebarView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.26, green: 0.51, blue: 0.94),
                                        Color(red: 0.39, green: 0.79, blue: 0.99)
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
                .background(Color.white.opacity(0.82), in: Capsule())
            }

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
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }

            Spacer()

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
        .padding(20)
        .background(SidebarBackground())
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
            Text("Bundled runtime, local model cache, and a workspace that feels native on macOS.")
                .foregroundStyle(WispPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
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
        .frame(maxWidth: .infinity, minHeight: 430)
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
                .frame(minHeight: 430)
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .background(Color.white.opacity(0.80), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.64), lineWidth: 1)
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
        .background(Color.white.opacity(0.80), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.64), lineWidth: 1)
        )
    }
}

private struct SectionHeader: View {
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
        .background(Color.white.opacity(0.74), in: Capsule())
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
        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                            Color(red: 0.27, green: 0.53, blue: 0.94).opacity(0.16),
                            Color(red: 0.36, green: 0.78, blue: 0.98).opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.84), Color.white.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.blue.opacity(0.34) : Color.white.opacity(0.58), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSelected ? .white : WispPalette.ink)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [
                            Color(red: 0.29, green: 0.53, blue: 0.94),
                            Color(red: 0.36, green: 0.78, blue: 0.98)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

private struct SidebarActionRow: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let action: () -> Void

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
            .padding(12)
            .background(Color.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
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
                                Color(red: 0.27, green: 0.53, blue: 0.94),
                                Color(red: 0.36, green: 0.78, blue: 0.98)
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
                    .background(Color.white.opacity(0.82), in: Capsule())
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
                    .fill(Color.white.opacity(0.82))
                    .frame(width: 44, height: 44)

                Image(systemName: symbolName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.tint)
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
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.72), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.55), lineWidth: 1))
    }
}

private struct DockButton: View {
    let title: String
    let symbolName: String
    var prominent = false
    let action: () -> Void

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
                                        Color(red: 0.29, green: 0.53, blue: 0.94),
                                        Color(red: 0.36, green: 0.78, blue: 0.98)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(Color.white.opacity(0.86)),
                        in: Circle()
                    )
                    .foregroundStyle(prominent ? .white : .primary)

                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WispPalette.ink)
            }
            .frame(width: 76, height: 82)
        }
        .buttonStyle(.plain)
    }
}

private struct ModelOptionCard: View {
    let model: LocalModel
    let isSelected: Bool
    let isCached: Bool
    let action: () -> Void

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
                            Color(red: 0.18, green: 0.43, blue: 0.88).opacity(0.16),
                            Color(red: 0.36, green: 0.78, blue: 0.98).opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.88), Color.white.opacity(0.74)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.blue.opacity(0.40) : Color.white.opacity(0.65), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                    Color(red: 0.10, green: 0.17, blue: 0.25),
                    Color(red: 0.16, green: 0.35, blue: 0.49)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 30, x: 0, y: 18)
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
            .background(.white.opacity(0.12), in: Capsule())
            .foregroundStyle(.white.opacity(0.86))
    }
}

private struct HeroActionButton: View {
    let title: String
    var prominent = false
    let action: () -> Void

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
                                Color(red: 0.16, green: 0.51, blue: 0.99),
                                Color(red: 0.30, green: 0.70, blue: 0.99)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color.white.opacity(0.14),
                                Color.white.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(prominent ? 0.0 : 0.10), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

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
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct AppChromeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.97, blue: 0.96),
                    Color(red: 0.93, green: 0.95, blue: 0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.62))
                .frame(width: 420, height: 420)
                .blur(radius: 38)
                .offset(x: 320, y: -220)

            Circle()
                .fill(Color(red: 0.65, green: 0.83, blue: 0.98).opacity(0.22))
                .frame(width: 430, height: 430)
                .blur(radius: 38)
                .offset(x: -290, y: 230)

            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .padding(18)
                .blur(radius: 30)
        }
        .ignoresSafeArea()
    }
}

private struct SidebarBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.92),
                Color(red: 0.95, green: 0.96, blue: 0.97)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private extension View {
    func panelBackground(prominent: Bool = true) -> some View {
        self
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(prominent ? 0.88 : 0.76),
                        Color(red: 0.90, green: 0.93, blue: 0.96).opacity(prominent ? 0.78 : 0.60)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.44), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 10)
    }
}

private enum WispPalette {
    static let ink = Color(red: 0.12, green: 0.16, blue: 0.22)
    static let muted = Color(red: 0.42, green: 0.48, blue: 0.57)
}
