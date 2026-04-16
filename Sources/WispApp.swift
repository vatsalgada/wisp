import SwiftUI
import OSLog

private let appLogger = Logger(subsystem: "com.wisp.app", category: "app")

@main
struct WispApp: App {
    @State private var appModel = AppModel()
    @State private var globalHotKeyManager = GlobalHotKeyManager()

    var body: some Scene {
        WindowGroup("Wisp", id: "main") {
            ContentView(appModel: appModel)
                .frame(minWidth: 880, minHeight: 640)
                .preferredColorScheme(appModel.themePreference.preferredColorScheme)
                .onAppear {
                    appLogger.notice("Main window appeared")
                    globalHotKeyManager.registerToggleHotKey {
                        Task { @MainActor in
                            await appModel.toggleDictation()
                        }
                    }
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Start Dictation") {
                    Task {
                        await appModel.startDictation()
                    }
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Button("Stop Dictation") {
                    Task {
                        await appModel.stopDictation()
                    }
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])
                .disabled(!appModel.isDictating)
            }
        }

        Settings {
            SettingsView(appModel: appModel)
                .frame(width: 560, height: 440)
                .preferredColorScheme(appModel.themePreference.preferredColorScheme)
        }

        MenuBarExtra("Wisp", systemImage: appModel.isDictating ? "waveform.circle.fill" : "waveform.circle") {
            MenuBarView(appModel: appModel)
        }
    }
}
