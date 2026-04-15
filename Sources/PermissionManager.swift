import AVFoundation
@preconcurrency
import ApplicationServices

enum PermissionState: String {
    case granted
    case denied
    case notDetermined
    case restricted

    var displayName: String {
        switch self {
        case .granted:
            return "Granted"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not requested"
        case .restricted:
            return "Restricted"
        }
    }

    var detailText: String {
        switch self {
        case .granted:
            return "Wisp can capture audio locally on this Mac."
        case .denied:
            return "System Settings needs a quick approval before recording can begin."
        case .notDetermined:
            return "The system prompt will appear the first time recording starts."
        case .restricted:
            return "This Mac is currently blocking microphone access."
        }
    }
}

enum PermissionManager {
    static func microphoneStatus() -> PermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .restricted
        }
    }

    static func requestMicrophoneAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    static func isAccessibilityTrusted(prompt: Bool) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
