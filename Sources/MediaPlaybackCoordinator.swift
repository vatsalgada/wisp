import AppKit
import Foundation

@MainActor
final class MediaPlaybackCoordinator {
    private struct PausedPlayer {
        let name: String
        let resumeScript: String
    }

    private var pausedPlayers: [PausedPlayer] = []

    func pauseForDictation() {
        pausedPlayers.removeAll()

        pausePlayer(
            name: "Music",
            bundleIdentifier: "com.apple.Music",
            pauseScript: """
            tell application id "com.apple.Music"
                if player state is playing then
                    pause
                    return "paused"
                end if
            end tell
            return ""
            """,
            resumeScript: """
            tell application id "com.apple.Music" to play
            """
        )

        pausePlayer(
            name: "Spotify",
            bundleIdentifier: "com.spotify.client",
            pauseScript: """
            tell application id "com.spotify.client"
                if player state is playing then
                    pause
                    return "paused"
                end if
            end tell
            return ""
            """,
            resumeScript: """
            tell application id "com.spotify.client" to play
            """
        )

        pausePlayer(
            name: "QuickTime Player",
            bundleIdentifier: "com.apple.QuickTimePlayerX",
            pauseScript: """
            tell application id "com.apple.QuickTimePlayerX"
                set playingDocuments to documents whose playing is true
                if (count of playingDocuments) > 0 then
                    set pausedNames to {}
                    repeat with playingDocument in playingDocuments
                        copy (name of playingDocument) to end of pausedNames
                    end repeat
                    pause playingDocuments
                    set AppleScript's text item delimiters to linefeed
                    set joinedNames to pausedNames as text
                    set AppleScript's text item delimiters to ""
                    return joinedNames
                end if
            end tell
            return ""
            """,
            resumeScript: """
            tell application id "com.apple.QuickTimePlayerX" to play document "%@"
            """
        )
    }

    func resumePausedMedia() {
        let playersToResume = pausedPlayers
        pausedPlayers.removeAll()

        for player in playersToResume {
            _ = runAppleScript(player.resumeScript)
        }
    }

    private func pausePlayer(name: String, bundleIdentifier: String, pauseScript: String, resumeScript: String) {
        guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty == false else {
            return
        }

        guard let result = runAppleScript(pauseScript), !result.isEmpty else {
            return
        }

        if name == "QuickTime Player" {
            for documentName in result.split(separator: "\n") {
                let escapedName = String(documentName).replacingOccurrences(of: "\"", with: "\\\"")
                pausedPlayers.append(PausedPlayer(name: name, resumeScript: String(format: resumeScript, escapedName)))
            }
        } else {
            pausedPlayers.append(PausedPlayer(name: name, resumeScript: resumeScript))
        }
    }

    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        return result?.stringValue
    }
}
