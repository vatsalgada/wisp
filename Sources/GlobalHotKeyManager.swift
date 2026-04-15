import Carbon
import Foundation

final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?

    func registerToggleHotKey(callback: @escaping () -> Void) {
        unregister()
        self.callback = callback

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if hotKeyID.id == 1 {
                    manager.callback?()
                }
                return noErr
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard status == noErr else { return }

        let hotKeyID = EventHotKeyID(signature: fourCharCode("WISP"), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_D),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregister()
    }
}

private func fourCharCode(_ string: String) -> FourCharCode {
    string.utf8.reduce(0) { ($0 << 8) + FourCharCode($1) }
}
