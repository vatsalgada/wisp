import SwiftUI

struct SettingsView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        Form {
            Toggle("Use push to talk", isOn: $appModel.usePushToTalk)
            Toggle("Launch at login", isOn: $appModel.launchAtLogin)

            LabeledContent("Hotkey") {
                Text(appModel.hotkey)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Default model") {
                Text(appModel.selectedModel.displayName)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Model cache") {
                Text(appModel.modelIsAvailable ? "Ready" : "Not downloaded")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}
