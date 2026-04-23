import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var appModel: AppModel

    var body: some View {
        Text(appModel.isDictating ? "Recording live" : "Ready for dictation")
            .foregroundStyle(.secondary)

        Button(appModel.isDictating ? "Stop Recording" : "Start Recording") {
            Task {
                if appModel.isDictating {
                    await appModel.stopDictation()
                } else {
                    await appModel.startDictation()
                }
            }
        }

        Button("Transcribe File…") {
            Task {
                await appModel.transcribeFromOpenPanel()
            }
        }

        Button("History…") {
            showMainWindow(selecting: .history)
        }

        Button("Permissions…") {
            showMainWindow(selecting: .permissions)
        }

        Button("Settings…") {
            showMainWindow(selecting: .settings)
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        Button("Show Main Window") {
            showMainWindow(selecting: .capture)
        }

        Menu(modelMenuTitle) {
            if appModel.installedModels.isEmpty {
                Text("No downloaded models yet")
            } else {
                ForEach(appModel.installedModels) { model in
                    Button(model.displayName) {
                        appModel.updateSelectedModel(model)
                    }
                }
            }

            Divider()

            Button("Manage Models…") {
                showMainWindow(selecting: .models)
            }
        }

        if !appModel.selectedModelIsInstalled {
            Button("Download Default Model") {
                Task {
                    await appModel.prepareModelIfNeeded()
                }
            }
        } else {
            Button("Show Default Model in Finder") {
                appModel.revealModelInFinder()
            }
        }

        Button("Open Transcript Folder") {
            appModel.revealTranscriptFolder()
        }

        Divider()

        Button("Copy Transcript") {
            appModel.copyLatestTranscript()
        }
        .disabled(appModel.latestTranscript.isEmpty)

        if appModel.clipboardClips.isEmpty {
            Text("No saved clips")
                .foregroundStyle(.secondary)
        } else {
            Divider()

            Text("Latest clips")
                .foregroundStyle(.secondary)

            ForEach(Array(appModel.clipboardClips.prefix(5))) { clip in
                Button(clipMenuTitle(for: clip)) {
                    appModel.copyClipboardClip(clip)
                }
            }
        }

        Button("Manage Clipboard…") {
            showMainWindow(selecting: .clipboard)
        }

        Divider()

        Text("Local sessions: \(appModel.transcriptHistory.count)")
            .foregroundStyle(.secondary)

        Text("Shortcut: \(appModel.hotkey)")
            .foregroundStyle(.secondary)

        Text("Version 0.1.0")
            .foregroundStyle(.secondary)

        Button("Quit") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
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
