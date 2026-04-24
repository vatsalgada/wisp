import SwiftUI

struct SettingsView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                SettingsPageContent(appModel: appModel, includeHeader: false, compactLayout: true)
                    .padding(20)
            }
            .background(WispPalette.canvasTop.ignoresSafeArea())
            .navigationTitle("Settings")
        }
        .frame(minWidth: 520, minHeight: 420)
    }
}

struct SettingsPageView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        SettingsPageContent(appModel: appModel, includeHeader: true, compactLayout: false)
    }
}

private struct SettingsPageContent: View {
    @Bindable var appModel: AppModel
    let includeHeader: Bool
    let compactLayout: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if includeHeader {
                SectionHeader(
                    title: "Preferences",
                    subtitle: "Set how Wisp looks, starts, and behaves."
                )
            }

            appearancePanel

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    behaviorPanel
                    modelPanel
                        .frame(width: compactLayout ? 280 : 320, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 18) {
                    behaviorPanel
                    modelPanel
                }
            }

            supportPanel
        }
    }

    private var appearancePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Appearance",
                subtitle: "Choose the app theme."
            )

            Picker("Theme", selection: themeBinding) {
                ForEach(AppModel.ThemePreference.allCases) { preference in
                    Label(preference.title, systemImage: preference.symbolName)
                        .tag(preference)
                }
            }
            .pickerStyle(.segmented)

            Text(appModel.themePreference == .system
                 ? "Wisp will follow your current macOS appearance."
                 : "Wisp now stays in \(appModel.themePreference.title.lowercased()) mode until you change it again.")
                .font(.subheadline)
                .foregroundStyle(WispPalette.muted)
        }
        .padding(20)
        .panelBackground()
    }

    private var behaviorPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Behavior",
                subtitle: "Choose how recording starts."
            )

            Toggle(isOn: $appModel.usePushToTalk) {
                SettingsToggleCopy(
                    title: "Use push to talk",
                    subtitle: "Hold the shortcut to capture only while you’re actively speaking."
                )
            }
            .toggleStyle(.switch)

            Divider()

            Toggle(isOn: $appModel.rememberCopiedText) {
                SettingsToggleCopy(
                    title: "Remember copied text",
                    subtitle: "Save copied text as local clips."
                )
            }
            .toggleStyle(.switch)

            Divider()

            Toggle(isOn: $appModel.launchAtLogin) {
                SettingsToggleCopy(
                    title: "Launch at login",
                    subtitle: "Keep Wisp ready in the menu bar whenever your Mac starts."
                )
            }
            .toggleStyle(.switch)

            Divider()

            settingsValueRow(
                title: "Keyboard shortcut",
                value: appModel.hotkey,
                subtitle: "Start or stop recording from anywhere."
            )
        }
        .padding(20)
        .panelBackground()
    }

    private var modelPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Models",
                subtitle: "Choose the local model Wisp uses."
            )

            settingsValueRow(
                title: "Default model",
                value: appModel.selectedModel.displayName,
                subtitle: appModel.selectedModelIsInstalled
                    ? "\(appModel.selectedModel.displayName) is ready."
                    : "Download \(appModel.selectedModel.displayName) before recording."
            )

            Divider()

            settingsValueRow(
                title: "Installed models",
                value: appModel.installedModelCountText,
                subtitle: "\(appModel.installedModelsStorageText) stored locally on this Mac."
            )

            HStack(spacing: 10) {
                Button("Manage models") {
                    appModel.selectedSidebarItem = .models
                }

                if !appModel.installedModels.isEmpty {
                    Button("Open models folder") {
                        appModel.openModelsFolder()
                    }
                }
            }
        }
        .padding(20)
        .panelBackground()
    }

    private var supportPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Recovery",
                subtitle: "Open the system settings Wisp may need."
            )

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    Button("Microphone settings") {
                        appModel.openMicrophoneSettings()
                    }

                    Button("Accessibility settings") {
                        appModel.openAccessibilitySettings()
                    }

                    Button("Open macOS settings") {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Button("Microphone settings") {
                        appModel.openMicrophoneSettings()
                    }

                    Button("Accessibility settings") {
                        appModel.openAccessibilitySettings()
                    }

                    Button("Open macOS settings") {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                }
            }
        }
        .padding(20)
        .panelBackground(prominent: false)
    }

    private var themeBinding: Binding<AppModel.ThemePreference> {
        Binding(
            get: { appModel.themePreference },
            set: { appModel.updateThemePreference($0) }
        )
    }

    private func settingsValueRow(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(WispPalette.ink)

                Spacer(minLength: 12)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WispPalette.accent)
                    .multilineTextAlignment(.trailing)
            }

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(WispPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SettingsToggleCopy: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(WispPalette.ink)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(WispPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
