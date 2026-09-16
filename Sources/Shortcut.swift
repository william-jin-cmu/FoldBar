import Carbon
import Foundation

@MainActor
final class Shortcut {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    var action: (() -> Void)?
    func configure(enabled: Bool) -> Bool {
        if let hotKey { UnregisterEventHotKey(hotKey); self.hotKey = nil }
        guard enabled else { return false }
        if handler == nil {
            var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            let pointer = Unmanaged.passUnretained(self).toOpaque()
            let result = InstallEventHandler(GetApplicationEventTarget(), { _, _, pointer in
                guard let pointer else { return OSStatus(eventNotHandledErr) }
                let shortcut = Unmanaged<Shortcut>.fromOpaque(pointer).takeUnretainedValue()
                DispatchQueue.main.async { shortcut.action?() }
                return noErr
            }, 1, &type, pointer, &handler)
            guard result == noErr else { return false }
        }
        let id = EventHotKeyID(signature: 0x464F4C44, id: 1)
        return RegisterEventHotKey(UInt32(kVK_ANSI_B), UInt32(cmdKey | optionKey), id, GetApplicationEventTarget(), 0, &hotKey) == noErr
    }
}
