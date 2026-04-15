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
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        Button("Show Main Window") {
            showMainWindow(selecting: .capture)
        }

        Menu("\(appModel.selectedModel.displayName) (\(appModel.selectedModel.recommendedLabel))") {
            ForEach(LocalModel.allCases) { model in
                Button(model.displayName) {
                    appModel.updateSelectedModel(model)
                }
            }
        }

        Button("Prepare Model") {
            Task {
                await appModel.prepareModelIfNeeded()
            }
        }

        Button("Open Transcript Folder") {
            appModel.revealTranscriptFolder()
        }

        Divider()

        Text("Local sessions: \(appModel.transcriptHistory.count)")
            .foregroundStyle(.secondary)

        Text("Shortcut: \(appModel.hotkey)")
            .foregroundStyle(.secondary)

        Text("Version 0.1.0")
            .foregroundStyle(.secondary)

        Button("Copy Transcript") {
            appModel.copyLatestTranscript()
        }
        .disabled(appModel.latestTranscript.isEmpty)

        Button("Quit") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func showMainWindow(selecting item: AppModel.SidebarItem) {
        appModel.selectedSidebarItem = item
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
