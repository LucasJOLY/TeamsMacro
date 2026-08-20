import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let activate = Self("activate")
    static let deactivate = Self("deactivate")
    static let toggle = Self(
        "toggle",
        default: .init(.t, modifiers: [.control, .option, .command])
    )
}
