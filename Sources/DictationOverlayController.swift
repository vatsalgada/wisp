import AppKit
import SwiftUI

@MainActor
final class DictationOverlayController {
    private var panel: NSPanel?

    func showListening() {
        show(state: .listening)
    }

    func showTranscribing() {
        show(state: .transcribing)
    }

    func showPasted() {
        show(state: .pasted)
        Task {
            try? await Task.sleep(for: .seconds(1.1))
            hide()
        }
    }

    func showCopied() {
        show(state: .copied)
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            hide()
        }
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func show(state: DictationOverlayState) {
        let overlay = DictationOverlayView(state: state)
        let hostingView = NSHostingView(rootView: overlay)
        let size = hostingView.fittingSize
        let panel = self.panel ?? makePanel()
        panel.contentView = hostingView
        panel.setContentSize(size)
        position(panel: panel, size: size)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 72),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        return panel
    }

    private func position(panel: NSPanel, size: NSSize) {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let origin = NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.maxY - size.height - 34
        )
        panel.setFrameOrigin(origin)
    }
}

private enum DictationOverlayState {
    case listening
    case transcribing
    case pasted
    case copied

    var title: String {
        switch self {
        case .listening:
            return "Listening"
        case .transcribing:
            return "Transcribing"
        case .pasted:
            return "Pasted"
        case .copied:
            return "Copied"
        }
    }

    var subtitle: String {
        switch self {
        case .listening:
            return "Release shortcut to finish"
        case .transcribing:
            return "Turning speech into text"
        case .pasted:
            return "Inserted into the active field"
        case .copied:
            return "Ready on the clipboard"
        }
    }

    var symbolName: String {
        switch self {
        case .listening:
            return "waveform"
        case .transcribing:
            return "text.bubble"
        case .pasted:
            return "checkmark"
        case .copied:
            return "doc.on.clipboard"
        }
    }

    var isActive: Bool {
        self == .listening || self == .transcribing
    }
}

private struct DictationOverlayView: View {
    let state: DictationOverlayState
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                if state.isActive {
                    Circle()
                        .stroke(Color.white.opacity(0.26), lineWidth: 2)
                        .scaleEffect(pulse ? 1.25 : 0.82)
                        .opacity(pulse ? 0.18 : 0.78)
                }

                Circle()
                    .fill(state == .listening ? Color.red : WispPalette.accent)

                Image(systemName: state.symbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(state.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(state.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(width: 286)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.black.opacity(0.76))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.84).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}
