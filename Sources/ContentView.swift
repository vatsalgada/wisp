import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var appModel: AppModel
    private let pageTopPadding: CGFloat = 28

    var body: some View {
        HSplitView {
            SidebarView(appModel: appModel, pageTopPadding: pageTopPadding)
                .frame(minWidth: 220, idealWidth: 248, maxWidth: 280)
                .id(appModel.selectedSidebarItem ?? .capture)

            ZStack {
                AppChromeBackground()
                detailContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .id(appModel.selectedSidebarItem ?? .capture)
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
            DetailScrollView(
                appModel: appModel,
                scrollIdentity: .capture,
                topPadding: pageTopPadding
            ) {
                CaptureDashboard(appModel: appModel)
            }
        case .clipboard:
            DetailScrollView(
                appModel: appModel,
                scrollIdentity: .clipboard,
                topPadding: pageTopPadding
            ) {
                ClipboardView(appModel: appModel)
            }
        case .history:
            DetailScrollView(
                appModel: appModel,
                scrollIdentity: .history,
                topPadding: pageTopPadding
            ) {
                HistoryView(appModel: appModel)
            }
        case .models:
            DetailScrollView(
                appModel: appModel,
                scrollIdentity: .models,
                topPadding: pageTopPadding
            ) {
                ModelsView(appModel: appModel)
            }
        case .permissions:
            DetailScrollView(
                appModel: appModel,
                scrollIdentity: .permissions,
                topPadding: pageTopPadding
            ) {
                PermissionsView(appModel: appModel)
            }
        case .settings:
            DetailScrollView(
                appModel: appModel,
                scrollIdentity: .settings,
                topPadding: pageTopPadding
            ) {
                SettingsPageView(appModel: appModel)
            }
        }
    }
}

private struct DetailScrollView<Content: View>: View {
    private let topAnchor = "detail-scroll-top"
    @Bindable var appModel: AppModel
    let scrollIdentity: AppModel.SidebarItem
    let topPadding: CGFloat
    @ViewBuilder let content: Content

    init(
        appModel: AppModel,
        scrollIdentity: AppModel.SidebarItem,
        topPadding: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.appModel = appModel
        self.scrollIdentity = scrollIdentity
        self.topPadding = topPadding
        self.content = content()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Color.clear
                    .frame(height: 1)
                    .id(topAnchor)

                VStack(alignment: .leading, spacing: 0) {
                    DetailHeader(appModel: appModel)
                        .padding(.bottom, 20)

                    content
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 28)
                .padding(.top, topPadding)
                .padding(.bottom, 28)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    proxy.scrollTo(topAnchor, anchor: .top)
                }
            }
            .onChange(of: scrollIdentity) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    proxy.scrollTo(topAnchor, anchor: .top)
                }
            }
        }
    }
}

private struct SidebarView: View {
    private let topAnchor = "sidebar-scroll-top"
    @Bindable var appModel: AppModel
    let pageTopPadding: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            sidebarHeader

            VStack(alignment: .leading, spacing: 6) {
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

            ScrollViewReader { proxy in
                ScrollView {
                    Color.clear
                        .frame(height: 1)
                        .id(topAnchor)

                    VStack(alignment: .leading, spacing: 22) {
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
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        proxy.scrollTo(topAnchor, anchor: .top)
                    }
                }
                .onChange(of: appModel.selectedSidebarItem ?? .capture) { _, _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        proxy.scrollTo(topAnchor, anchor: .top)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, pageTopPadding)
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
                        .frame(width: 42, height: 42)

                    Image(systemName: "waveform")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wisp")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(WispPalette.ink)
                    Text("Local dictation")
                        .font(.subheadline)
                        .foregroundStyle(WispPalette.muted)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                if appModel.isDictating {
                    ListeningPulse()
                } else {
                    StatusDot(color: .green)
                }

                Text(appModel.isDictating ? "Listening" : "Ready")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(appModel.isDictating ? WispPalette.ink : WispPalette.muted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
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
            return "Record locally, keep clips close, and move on."
        case .clipboard:
            return "Keep useful clips close."
        case .history:
            return "Browse, copy, and reopen past transcripts."
        case .models:
            return "Pick the speed and accuracy you want."
        case .permissions:
            return "Make sure Wisp can record and paste."
        case .settings:
            return "Set defaults once, then stay out of the way."
        }
    }
}

private struct CaptureDashboard: View {
    @Bindable var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            captureConsole
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    latestTranscriptPanel
                    clipboardPanel
                        .frame(width: 300)
                }

                VStack(alignment: .leading, spacing: 18) {
                    latestTranscriptPanel
                    clipboardPanel
                }
            }
        }
    }

    private var captureConsole: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 20) {
                    primaryCaptureButton
                    captureStatusBlock
                    Spacer(minLength: 16)
                    waveformMeter
                }

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 16) {
                        primaryCaptureButton
                        captureStatusBlock
                    }
                    waveformMeter
                }
            }

            HStack(spacing: 10) {
                readinessPill(
                    title: appModel.microphonePermission == .granted ? "Mic ready" : "Mic needs approval",
                    symbolName: appModel.microphonePermission == .granted ? "mic.fill" : "mic.badge.xmark",
                    isReady: appModel.microphonePermission == .granted
                )
                readinessPill(
                    title: appModel.modelIsAvailable ? "\(appModel.selectedModel.displayName) ready" : "Model needed",
                    symbolName: appModel.modelIsAvailable ? "cpu.fill" : "arrow.down.circle",
                    isReady: appModel.modelIsAvailable
                )
                readinessPill(
                    title: "\(appModel.clipboardClips.count) clips",
                    symbolName: "doc.on.clipboard",
                    isReady: !appModel.clipboardClips.isEmpty
                )
                Spacer()
                Button("Settings") {
                    appModel.selectedSidebarItem = .settings
                }
                .buttonStyle(.borderless)
            }
            .font(.caption.weight(.semibold))

            if let errorMessage = appModel.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
        .padding(18)
        .panelBackground()
    }

    private var primaryCaptureButton: some View {
        Button {
            Task {
                await performPrimaryCaptureAction()
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(appModel.isDictating ? Color.red.opacity(0.92) : WispPalette.accent)
                        .frame(width: 56, height: 56)
                    Image(systemName: appModel.isDictating ? "stop.fill" : "mic.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }

                Text(primaryCaptureTitle)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(WispPalette.ink)
            }
            .frame(width: 118, height: 100)
            .background(
                WispPalette.subtlePanelTop,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(WispPalette.panelStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!appModel.canStartDictation && !appModel.canStopDictation)
    }

    private var captureStatusBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appModel.isDictating ? "Listening" : "Capture")
                .font(.title2.weight(.semibold))
                .foregroundStyle(WispPalette.ink)
            Text(captureStatusText)
                .font(.callout)
                .foregroundStyle(WispPalette.muted)
                .lineLimit(2)
            HStack(spacing: 8) {
                Text(appModel.workflowState.displayName)
                Text("•")
                Text("\(appModel.latestTranscriptWordCount) words")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(WispPalette.muted)
        }
        .frame(maxWidth: 320, alignment: .leading)
    }

    private var waveformMeter: some View {
        HStack(alignment: .center, spacing: 5) {
            ForEach(0..<18, id: \.self) { index in
                Capsule()
                    .fill(appModel.isDictating ? WispPalette.accent : WispPalette.muted.opacity(0.35))
                    .frame(width: 6, height: waveformHeight(at: index))
                    .animation(.easeInOut(duration: 0.28), value: appModel.isDictating)
            }
        }
        .frame(width: 172, height: 68)
        .padding(.horizontal, 14)
        .background(WispPalette.subtlePanelTop, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(WispPalette.panelStroke, lineWidth: 1)
        )
    }

    private var latestTranscriptPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                SectionHeader(
                    title: "Latest",
                    subtitle: "Newest capture."
                )
                Spacer()
                Button("History") {
                    appModel.selectedSidebarItem = .history
                }
                .buttonStyle(.borderless)
            }

            if appModel.latestTranscript.isEmpty {
                EmptyStateBanner(
                    title: "Nothing yet",
                    subtitle: "The mic is being dramatic."
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(appModel.latestTranscript)
                        .font(.body)
                        .foregroundStyle(WispPalette.ink)
                        .lineLimit(8)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)

                    HStack(spacing: 10) {
                        Button("Copy") {
                            appModel.copyLatestTranscript()
                        }
                        Button("Save clip") {
                            appModel.saveLatestTranscriptAsClip()
                        }
                        Spacer()
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(18)
        .panelBackground()
    }

    private var clipboardPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(
                    title: "Clipboard",
                    subtitle: "\(appModel.clipboardClips.count) saved clips"
                )
                Spacer()
                Button("Open") {
                    appModel.selectedSidebarItem = .clipboard
                }
                .buttonStyle(.borderless)
            }

            if appModel.clipboardClips.isEmpty {
                EmptyStateBanner(
                    title: "No clips saved",
                    subtitle: "Future-you has no souvenirs."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(appModel.clipboardClips.prefix(3))) { clip in
                        Button {
                            appModel.selectClipboardClip(clip)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "doc.on.clipboard")
                                    .foregroundStyle(WispPalette.muted)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(clip.text)
                                        .font(.callout)
                                        .foregroundStyle(WispPalette.ink)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Text(clip.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(WispPalette.muted)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(WispPalette.subtlePanelTop, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(18)
        .panelBackground()
    }

    private var primaryCaptureTitle: String {
        if appModel.isDictating {
            return "Stop"
        }
        if appModel.microphonePermission == .notDetermined {
            return "Allow mic"
        }
        if appModel.microphonePermission != .granted {
            return "Open mic"
        }
        if !appModel.modelIsAvailable {
            return "Prepare"
        }
        return "Start"
    }

    private var captureStatusText: String {
        if appModel.isDictating {
            return "Listening locally on this Mac."
        }
        if appModel.microphonePermission != .granted {
            return "Microphone permission is needed before recording."
        }
        if !appModel.modelIsAvailable {
            return "Prepare the local model once before recording."
        }
        if appModel.latestTranscript.isEmpty {
            return "Ready for a fresh dictation."
        }
        return "Latest transcript is ready."
    }

    private func readinessPill(title: String, symbolName: String, isReady: Bool) -> some View {
        Label(title, systemImage: symbolName)
            .foregroundStyle(isReady ? WispPalette.ink : WispPalette.muted)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(WispPalette.subtlePanelTop, in: Capsule())
    }

    private func waveformHeight(at index: Int) -> CGFloat {
        let idlePattern: [CGFloat] = [16, 28, 20, 34, 18, 26]
        let activePattern: [CGFloat] = [20, 44, 32, 58, 26, 64, 36, 52]
        let pattern = appModel.isDictating ? activePattern : idlePattern
        return pattern[index % pattern.count]
    }

    private func performPrimaryCaptureAction() async {
        if appModel.isDictating {
            await appModel.stopDictation()
            return
        }

        appModel.refreshEnvironment()

        if appModel.microphonePermission == .notDetermined {
            await appModel.requestMicrophoneAccess()
            guard appModel.microphonePermission == .granted else { return }
        } else if appModel.microphonePermission != .granted {
            appModel.openMicrophoneSettings()
            return
        }

        if !appModel.modelIsAvailable {
            await appModel.prepareModelIfNeeded()
            guard appModel.modelIsAvailable else { return }
        }

        await appModel.startDictation()
    }
}

private struct HistoryView: View {
    @Bindable var appModel: AppModel
    @State private var copiedRecordID: AppModel.TranscriptRecord.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "History",
                subtitle: "Past transcripts, ready when you need them."
            )

            if appModel.transcriptHistory.isEmpty {
                EmptyStateBanner(
                    title: "No transcripts yet",
                    subtitle: "Future-you is waiting for notes."
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
                Button("Open folder") {
                    appModel.revealTranscriptFolder()
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                HistorySearchField(text: $appModel.historySearchText)
                Button("Open folder") {
                    appModel.revealTranscriptFolder()
                }
            }
        }
    }

    private var historyListPanel: some View {
        ScrollView {
            if appModel.filteredTranscriptHistory.isEmpty {
                EmptyStateBanner(
                    title: "No matches",
                    subtitle: "That phrase is hiding somewhere else."
                )
                .padding(.top, 2)
            } else {
                VStack(spacing: 12) {
                    ForEach(appModel.filteredTranscriptHistory) { record in
                        HistoryRow(
                            record: record,
                            isSelected: appModel.selectedTranscriptRecordID == record.id,
                            isCopied: copiedRecordID == record.id
                        ) {
                            appModel.selectTranscript(record)
                            showCopiedFeedback(for: record)
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

                ScrollView {
                    Text(selectedRecord.text)
                        .font(.body)
                        .foregroundStyle(Color.black.opacity(0.88))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(14)
                }
                .frame(maxWidth: .infinity, minHeight: 360, alignment: .topLeading)
                .background(
                    Color.white.opacity(0.97),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )

                HStack {
                    Button(role: .destructive) {
                        appModel.deleteTranscript(selectedRecord)
                    } label: {
                        Text("Delete transcript")
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
            Text("Saved locally")
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
            showCopiedFeedback(for: selectedRecord)
        }

        Button("Insert") {
            appModel.insertTranscript(selectedRecord)
        }

        Button("Reveal in Finder") {
            appModel.revealTranscriptInFinder(selectedRecord)
        }

        Button("Open file") {
            appModel.openTranscriptFile(selectedRecord)
        }
    }

    private func showCopiedFeedback(for record: AppModel.TranscriptRecord) {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) {
            copiedRecordID = record.id
        }

        Task {
            try? await Task.sleep(for: .seconds(1.3))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.22)) {
                    if copiedRecordID == record.id {
                        copiedRecordID = nil
                    }
                }
            }
        }
    }
}

private struct ClipboardView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Clipboard",
                subtitle: "Saved clips for later."
            )

            clipboardToolbar

            if appModel.clipboardClips.isEmpty {
                EmptyStateBanner(
                    title: "No clips saved",
                    subtitle: "Future-you has no souvenirs."
                )
                .panelBackground()
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    clipListPanel

                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            appModel.clearClipboardClips()
                        } label: {
                            Text("Clear clipboard")
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var clipboardToolbar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                HistorySearchField(text: $appModel.clipboardSearchText, placeholder: "Search clips")
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                HistorySearchField(text: $appModel.clipboardSearchText, placeholder: "Search clips")
            }
        }
    }

    private var clipListPanel: some View {
        ScrollView {
            if appModel.filteredClipboardClips.isEmpty {
                EmptyStateBanner(
                    title: "No matches",
                    subtitle: "That clip is on another adventure."
                )
                .padding(.top, 2)
            } else {
                VStack(spacing: 12) {
                    ForEach(appModel.filteredClipboardClips) { clip in
                        ClipboardRow(
                            clip: clip,
                            isSelected: appModel.selectedClipboardClipID == clip.id,
                            copyAction: {
                                appModel.copyClipboardClip(clip)
                            },
                            insertAction: {
                                appModel.insertClipboardClip(clip)
                            },
                            deleteAction: {
                                appModel.deleteClipboardClip(clip)
                            }
                        )
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, minHeight: 320, alignment: .top)
        .padding(10)
        .panelBackground()
    }
}

private struct ClipboardRow: View {
    let clip: AppModel.ClipboardClip
    let isSelected: Bool
    let copyAction: () -> Void
    let insertAction: () -> Void
    let deleteAction: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(clip.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WispPalette.muted)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "doc.on.clipboard")
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }

                Text(clip.source)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WispPalette.muted)
                    .lineLimit(1)

                Text(clip.text)
                    .foregroundStyle(WispPalette.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: copyAction)

            Button("Insert", action: insertAction)

            Button(role: .destructive, action: deleteAction) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
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
        .onHover { hovering in
            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                isHovered = hovering
            }
        }
    }
}

private struct EmptyTranscriptPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transcript will appear here")
                .font(.headline)
                .foregroundStyle(WispPalette.ink)
            Text("Start recording and Wisp will fill this in.")
                .font(.subheadline)
                .foregroundStyle(WispPalette.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 320, alignment: .topLeading)
        .padding(18)
        .background(
            Color.white.opacity(0.97),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }
}

private struct ModelsView: View {
    @Bindable var appModel: AppModel
    private let cardColumns = [GridItem(.adaptive(minimum: 270), spacing: 16)]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Models",
                subtitle: "Choose the local model that fits the job."
            )

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 18) {
                        installedModelsSection
                        downloadMoreSection
                    }

                    ModelStorageCard(appModel: appModel)
                        .frame(width: 280, alignment: .top)
                }

                VStack(alignment: .leading, spacing: 18) {
                    ModelStorageCard(appModel: appModel)
                    installedModelsSection
                    downloadMoreSection
                }
            }
        }
    }

    private var installedModelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Installed models",
                subtitle: "Ready to use."
            )

            if appModel.installedModels.isEmpty {
                EmptyStateBanner(
                    title: "No models downloaded yet",
                    subtitle: "Start with base.en on most Macs."
                )
            } else {
                LazyVGrid(columns: cardColumns, spacing: 16) {
                    ForEach(appModel.installedModels) { model in
                        InstalledModelCard(
                            model: model,
                            isDefault: appModel.selectedModel == model
                        ) {
                            appModel.updateSelectedModel(model)
                        } onReveal: {
                            appModel.revealModelInFinder(model)
                        }
                    }
                }
            }
        }
        .padding(20)
        .panelBackground()
    }

    private var downloadMoreSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Download more",
                subtitle: "More accuracy usually means more waiting."
            )

            if appModel.downloadableModels.isEmpty {
                EmptyStateBanner(
                    title: "Everything is already installed",
                    subtitle: "Nothing left to collect here."
                )
            } else {
                LazyVGrid(columns: cardColumns, spacing: 16) {
                    ForEach(appModel.downloadableModels) { model in
                        DownloadableModelCard(
                            model: model,
                            isRecommended: model == .baseEnglish
                        ) {
                            Task {
                                await appModel.downloadModel(model)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .panelBackground(prominent: false)
    }
}

private struct PermissionsView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Permissions",
                subtitle: "Microphone for recording. Accessibility for pasting."
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
                title: "Permission check",
                subtitle: "If macOS asks, grant access once. Wisp will remember.",
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
            actionTitle: "Request microphone",
            secondaryActionTitle: "Open settings",
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
                ? "Wisp can paste when you choose Insert."
                : "Enable this to let Wisp paste for you.",
            actionTitle: "Open accessibility prompt",
            secondaryActionTitle: "System settings",
            symbolName: "rectangle.on.rectangle"
        ) {
            appModel.requestAccessibilityAccess()
        } secondaryAction: {
            appModel.openAccessibilitySettings()
        }
    }
}

private struct HeaderSearchField: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
            Text("Local on this Mac")
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
    var placeholder = "Search transcripts"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
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
    let isCopied: Bool
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
                    if isCopied {
                        Label("Copied", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "arrow.right.circle")
                            .foregroundStyle(isSelected ? .blue : .secondary)
                    }
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
            HeaderPill(title: "\(appModel.clipboardClips.count) clips", symbolName: "doc.on.clipboard")
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
                Capsule()
                    .fill(isSelected ? WispPalette.accent : Color.clear)
                    .frame(width: 3, height: 20)

                Image(systemName: symbolName)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 18)
                    .foregroundStyle(isSelected ? WispPalette.accent : WispPalette.muted)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WispPalette.ink)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected ? WispPalette.accent.opacity(0.34) : Color.clear,
                        lineWidth: 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
                isHovered = hovering
            }
        }
    }

    private var rowBackground: Color {
        if isSelected {
            return WispPalette.accentSoft
        }
        return isHovered ? WispPalette.subtlePanelTop : .clear
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

private struct InstalledModelCard: View {
    let model: LocalModel
    let isDefault: Bool
    let onSelectDefault: () -> Void
    let onReveal: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(WispPalette.ink)
                    Text(model.recommendedLabel.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WispPalette.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    if isDefault {
                        ModelBadge(title: "Default", tone: .accent)
                    }
                    ModelBadge(title: "Downloaded", tone: .success)
                }
            }

            Text(model.summary)
                .font(.subheadline)
                .foregroundStyle(WispPalette.muted)
                .lineLimit(3)

            HStack(spacing: 10) {
                MetadataPill(title: model.approximateSize, symbolName: "internaldrive")
                MetadataPill(title: "On this Mac", symbolName: "checkmark.circle")
            }

            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: 12) {
                if isDefault {
                    Label("Default model", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WispPalette.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(WispPalette.accentSoft, in: Capsule())
                } else {
                    Button("Use by Default", action: onSelectDefault)
                        .buttonStyle(.borderedProminent)
                        .tint(WispPalette.accent)
                }

                Spacer()

                ModelTextAction(title: "Show in Finder", systemImage: "arrow.up.right.square", action: onReveal)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 228, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: isDefault
                    ? [
                        WispPalette.accent.opacity(0.15),
                        WispPalette.accentWash.opacity(0.20)
                    ]
                    : [
                        WispPalette.panelTop,
                        WispPalette.panelBottom
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isDefault ? WispPalette.accent.opacity(0.45) : WispPalette.panelStroke, lineWidth: 1)
        )
        .shadow(color: isHovered ? WispPalette.shadow.opacity(0.55) : .clear, radius: 18, x: 0, y: 12)
        .scaleEffect(isHovered ? 1.01 : 1)
        .onHover { hovering in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                isHovered = hovering
            }
        }
    }
}

private struct DownloadableModelCard: View {
    let model: LocalModel
    let isRecommended: Bool
    let onDownload: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(WispPalette.ink)
                    Text(model.recommendedLabel.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WispPalette.muted)
                }

                Spacer()

                ModelBadge(
                    title: isRecommended ? "Recommended" : "Available",
                    tone: isRecommended ? .accent : .neutral
                )
            }

            Text(model.summary)
                .font(.subheadline)
                .foregroundStyle(WispPalette.muted)
                .lineLimit(3)

            HStack(spacing: 10) {
                MetadataPill(title: model.approximateSize, symbolName: "arrow.down.circle")
                if isRecommended {
                    MetadataPill(title: "Good default", symbolName: "sparkles")
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button("Download", action: onDownload)
                    .buttonStyle(.bordered)

                Spacer()

                Text("Stored locally after download")
                    .font(.subheadline)
                    .foregroundStyle(WispPalette.muted)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [WispPalette.subtlePanelTop, WispPalette.subtlePanelBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(WispPalette.panelStroke, lineWidth: 1)
        )
        .shadow(color: isHovered ? WispPalette.shadow.opacity(0.5) : .clear, radius: 18, x: 0, y: 12)
        .scaleEffect(isHovered ? 1.01 : 1)
        .onHover { hovering in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                isHovered = hovering
            }
        }
    }
}

private struct ModelStorageCard: View {
    @Bindable var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Storage",
                subtitle: "Models stored on this Mac."
            )

            VStack(alignment: .leading, spacing: 12) {
                ModelStorageRow(title: "Installed", value: appModel.installedModelCountText)
                ModelStorageRow(title: "Space used", value: appModel.installedModelsStorageText)
                ModelStorageRow(
                    title: "Default",
                    value: appModel.selectedModelIsInstalled ? appModel.selectedModel.displayName : "Not downloaded yet"
                )
            }

            Text("Wisp keeps model files in Application Support.")
                .font(.subheadline)
                .foregroundStyle(WispPalette.muted)
                .fixedSize(horizontal: false, vertical: true)

            Button("Open models folder") {
                appModel.openModelsFolder()
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .panelBackground()
    }
}

private struct ModelStorageRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(WispPalette.muted)
                .textCase(.uppercase)
            Text(value)
                .font(.headline)
                .foregroundStyle(WispPalette.ink)
        }
    }
}

private struct ModelBadge: View {
    enum Tone {
        case accent
        case success
        case neutral
    }

    let title: String
    let tone: Tone

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(backgroundColor, in: Capsule())
    }

    private var foregroundColor: Color {
        switch tone {
        case .accent:
            return WispPalette.accent
        case .success:
            return Color.green
        case .neutral:
            return WispPalette.ink
        }
    }

    private var backgroundColor: Color {
        switch tone {
        case .accent:
            return WispPalette.accentSoft
        case .success:
            return Color.green.opacity(0.14)
        case .neutral:
            return WispPalette.subtlePanelTop
        }
    }
}

private struct ModelTextAction: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
        }
        .buttonStyle(.plain)
        .foregroundStyle(WispPalette.muted)
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

private struct ListeningPulse: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(WispPalette.accent.opacity(0.28), lineWidth: 2)
                .frame(width: 18, height: 18)
                .scaleEffect(isAnimating ? 1.35 : 0.75)
                .opacity(isAnimating ? 0.1 : 0.9)

            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
        }
        .frame(width: 20, height: 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.86).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
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
                    HeroTag(title: "On device")
                    HeroTag(title: "Local models")
                    HeroTag(title: "Menu bar ready")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Wisp")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Fast local dictation for macOS.")
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
            title: appModel.isDictating ? "Stop recording" : "Start recording",
            prominent: true
        ) {
            Task {
                await appModel.toggleDictation()
            }
        }

        HeroActionButton(title: "Transcribe file…") {
            Task {
                await appModel.transcribeFromOpenPanel()
            }
        }

        HeroActionButton(title: "Prepare model") {
            Task {
                await appModel.prepareModelIfNeeded()
            }
        }
    }

    private var heroMetrics: some View {
        VStack(alignment: .leading, spacing: 14) {
            HeroMetricCard(
                title: appModel.workflowState.displayName,
                subtitle: "Status",
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
