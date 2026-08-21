from __future__ import annotations

from collections.abc import Callable

from pynput import keyboard


class HotkeyManager:
    def __init__(self) -> None:
        self._listener: keyboard.GlobalHotKeys | None = None

    def update(
        self,
        *,
        activate: str,
        deactivate: str,
        toggle: str,
        on_activate: Callable[[], None],
        on_deactivate: Callable[[], None],
        on_toggle: Callable[[], None],
    ) -> None:
        self.stop()
        mapping: dict[str, Callable[[], None]] = {}
        if activate.strip():
            mapping[activate.strip()] = on_activate
        if deactivate.strip():
            mapping[deactivate.strip()] = on_deactivate
        if toggle.strip():
            mapping[toggle.strip()] = on_toggle
        if not mapping:
            return
        try:
            self._listener = keyboard.GlobalHotKeys(mapping)
            self._listener.start()
        except Exception:
            # Raccourci invalide : on ignore pour ne pas planter l’app.
            self._listener = None

    def stop(self) -> None:
        if self._listener is not None:
            self._listener.stop()
            self._listener = None
