import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var appModel: AppModel

    var body: some View {
        Text(appModel.isDictating ? "Recording" : "Ready")
            .foregroundStyle(.secondary)

        Button(appModel.isDictating ? "Stop recording" : "Start recording") {
            Task {
                if appModel.isDictating {
                    await appModel.stopDictation()
                } else {
                    await appModel.startDictation()
                }
            }
        }

        Button("Transcribe file…") {
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

        Button("Show Wisp") {
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

            Button("Manage models…") {
                showMainWindow(selecting: .models)
            }
        }

        if !appModel.selectedModelIsInstalled {
            Button("Download default model") {
                Task {
                    await appModel.prepareModelIfNeeded()
                }
            }
        } else {
            Button("Show default model in Finder") {
                appModel.revealModelInFinder()
            }
        }

        Button("Open transcript folder") {
            appModel.revealTranscriptFolder()
        }

        Divider()

        Button("Copy transcript") {
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

        Button("Manage clipboard…") {
            showMainWindow(selecting: .clipboard)
        }

        Divider()

        Text("Sessions: \(appModel.transcriptHistory.count)")
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
