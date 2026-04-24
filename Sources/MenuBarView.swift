import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var appModel: AppModel

    var body: some View {
        Text(menuStateTitle)
            .foregroundStyle(.secondary)

        primaryRecordingButton

        Divider()

        Button("Show Wisp") {
            showMainWindow(selecting: .capture)
        }

        Button("History") {
            showMainWindow(selecting: .history)
        }

        Button("Clipboard") {
            showMainWindow(selecting: .clipboard)
        }

        Button("Settings") {
            showMainWindow(selecting: .settings)
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        Button("Copy latest transcript") {
            appModel.copyLatestTranscript()
        }
        .disabled(appModel.latestTranscript.isEmpty)

        recentClipsMenu

        if !appModel.selectedModelIsInstalled {
            Button("Download default model") {
                Task {
                    await appModel.prepareModelIfNeeded()
                }
            }
        }

        Divider()

        MoreMenu(
            appModel: appModel,
            modelMenuTitle: modelMenuTitle,
            showMainWindow: showMainWindow(selecting:)
        )

        Button("Permissions") {
            showMainWindow(selecting: .permissions)
        }

        Divider()

        Text("Shortcut: \(appModel.hotkey)")
            .foregroundStyle(.secondary)

        Text("Sessions: \(appModel.transcriptHistory.count)")
            .foregroundStyle(.secondary)

        Text("Version 0.1.0")
            .foregroundStyle(.secondary)

        Button("Quit") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private var menuStateTitle: String {
        switch appModel.workflowState {
        case .recording:
            return "Recording"
        case .transcribing:
            return "Transcribing"
        case .failed:
            return "Needs attention"
        case .preparing:
            return "Preparing"
        case .idle, .ready:
            return "Ready"
        }
    }

    private var primaryRecordingButton: some View {
        Button(appModel.isDictating ? "Stop recording" : "Start recording") {
            Task {
                if appModel.isDictating {
                    await appModel.stopDictation()
                } else {
                    await appModel.startDictation(insertAfterTranscription: true)
                }
            }
        }
    }

    @ViewBuilder
    private var recentClipsMenu: some View {
        if appModel.clipboardClips.isEmpty {
            Text("No clips saved")
                .foregroundStyle(.secondary)
        } else {
            Menu("Recent clips") {
                ForEach(Array(appModel.clipboardClips.prefix(3))) { clip in
                    Button(clipMenuTitle(for: clip)) {
                        appModel.copyClipboardClip(clip)
                    }
                }
            }
        }
    }

    private var modelMenuTitle: String {
        if appModel.selectedModelIsInstalled {
            return "\(appModel.selectedModel.displayName) (default)"
        }

        if let firstInstalled = appModel.installedModels.first {
            return "\(firstInstalled.displayName) available"
        }

        return "Models"
    }

    private func clipMenuTitle(for clip: AppModel.ClipboardClip) -> String {
        let singleLine = clip.text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let limit = 46

        if singleLine.count > limit {
            return "\(singleLine.prefix(limit))..."
        }

        return singleLine.isEmpty ? "Untitled clip" : singleLine
    }

    private func showMainWindow(selecting item: AppModel.SidebarItem) {
        appModel.selectedSidebarItem = item
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct MoreMenu: View {
    @Bindable var appModel: AppModel
    let modelMenuTitle: String
    let showMainWindow: (AppModel.SidebarItem) -> Void

    var body: some View {
        Menu("More") {
            Button("Transcribe file…") {
                Task {
                    await appModel.transcribeFromOpenPanel()
                }
            }

            Button("Open transcript folder") {
                appModel.revealTranscriptFolder()
            }

            if appModel.selectedModelIsInstalled {
                Button("Show default model in Finder") {
                    appModel.revealModelInFinder()
                }
            }

            Divider()

            modelMenu

            Button("Manage models…") {
                showMainWindow(.models)
            }

            Button("Manage clipboard…") {
                showMainWindow(.clipboard)
            }
        }
    }

    private var modelMenu: some View {
        Menu(modelMenuTitle) {
            if appModel.installedModels.isEmpty {
                Text("No downloaded models yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(appModel.installedModels) { model in
                    Button(model.displayName) {
                        appModel.updateSelectedModel(model)
                    }
                }
            }
        }
    }
}
