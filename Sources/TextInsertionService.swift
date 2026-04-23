import AppKit
import Foundation

enum TextInsertionError: LocalizedError {
    case accessibilityUnavailable
    case keyboardEventCreationFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityUnavailable:
            return "Accessibility access is required to paste into another app."
        case .keyboardEventCreationFailed:
            return "The keyboard paste event could not be created."
        }
    }
}

@MainActor
struct TextInsertionService {
    var pasteboardChangeCount: Int {
        NSPasteboard.general.changeCount
    }

    func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func readPasteboardString() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    func insertFromPasteboard() throws {
        guard PermissionManager.isAccessibilityTrusted(prompt: false) else {
            throw TextInsertionError.accessibilityUnavailable
        }

        let keyCodeV: CGKeyCode = 9
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: false) else {
            throw TextInsertionError.keyboardEventCreationFailed
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
