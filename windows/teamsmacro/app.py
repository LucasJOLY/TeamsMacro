from __future__ import annotations

import threading
import time
from datetime import datetime

import pystray
from pystray import MenuItem as Item

from teamsmacro import hotkeys as hotkeys_mod
from teamsmacro import mouse, startup
from teamsmacro.icons import make_tray_icon
from teamsmacro.settings import AppSettings
from teamsmacro.ui_settings import SettingsWindow


class TeamsMacroApp:
    def __init__(self) -> None:
        self.settings = AppSettings.load()
        self.enabled = False
        self.last_jiggle_at: datetime | None = None
        self.schedule_wants_active = False

        self._stop_event = threading.Event()
        self._jiggle_thread: threading.Thread | None = None
        self._hotkeys = hotkeys_mod.HotkeyManager()
        self._icon: pystray.Icon | None = None
        self._settings_lock = threading.Lock()

        if self.settings.launch_at_startup != startup.is_enabled():
            startup.set_enabled(self.settings.launch_at_startup)

    def run(self) -> None:
        self._reload_hotkeys()
        self._start_schedule_loop()
        self._sync_schedule()

        self._icon = pystray.Icon(
            "TeamsMacro",
            make_tray_icon(active=self.enabled),
            f"Teams Macro — {self.status_line()}",
            menu=self._make_menu(),
        )
        self._icon.run()

    def shutdown(self, _icon: pystray.Icon | None = None, _item: Item | None = None) -> None:
        self.enabled = False
        self._stop_event.set()
        self._hotkeys.stop()
        if self._icon is not None:
            self._icon.stop()

    def activate(self, _icon: pystray.Icon | None = None, _item: Item | None = None) -> None:
        if self.enabled:
            return
        self.enabled = True
        self._start_jiggle_loop()
        self._refresh_tray()

    def deactivate(self, _icon: pystray.Icon | None = None, _item: Item | None = None) -> None:
        was_enabled = self.enabled
        self.enabled = False
        if was_enabled:
            self._refresh_tray()

    def toggle(self, _icon: pystray.Icon | None = None, _item: Item | None = None) -> None:
        if self.enabled:
            self.deactivate()
        else:
            self.activate()

    def status_line(self) -> str:
        if self.enabled:
            return "Actif"
        if self.settings.schedule.enabled:
            if self.settings.schedule.is_within_lunch_break():
                return "Pause midi"
            if self.schedule_wants_active:
                return "En attente (planifié)"
            return "Inactif (hors créneau)"
        return "Inactif"

    def _make_menu(self) -> pystray.Menu:
        items: list[Item] = [
            Item(lambda text: self.status_line(), None, enabled=False),
        ]
        if self.settings.schedule.enabled:
            items.append(
                Item(lambda text: self.settings.schedule.summary(), None, enabled=False)
            )
        if self.last_jiggle_at is not None:
            stamp = self.last_jiggle_at.strftime("%H:%M:%S")
            items.append(Item(f"Dernier mouvement : {stamp}", None, enabled=False))

        items.extend(
            [
                Item(
                    lambda text: "Désactiver" if self.enabled else "Activer",
                    self.toggle,
                ),
                Item("Réglages…", self._open_settings),
                Item("Quitter", self.shutdown),
            ]
        )
        return pystray.Menu(*items)

    def _open_settings(
        self, _icon: pystray.Icon | None = None, _item: Item | None = None
    ) -> None:
        def worker() -> None:
            with self._settings_lock:
                # Copie des réglages pour l’UI.
                current = AppSettings.load()
                window = SettingsWindow(current, on_save=self._apply_settings)
                window.run()

        threading.Thread(target=worker, daemon=True).start()

    def _apply_settings(self, settings: AppSettings) -> None:
        self.settings = settings
        settings.save()
        startup.set_enabled(settings.launch_at_startup)
        self._reload_hotkeys()
        if self.enabled:
            self.deactivate()
            self.activate()
        self._sync_schedule()
        self._refresh_tray()

    def _reload_hotkeys(self) -> None:
        self._hotkeys.update(
            activate=self.settings.hotkey_activate,
            deactivate=self.settings.hotkey_deactivate,
            toggle=self.settings.hotkey_toggle,
            on_activate=lambda: self.activate(),
            on_deactivate=lambda: self.deactivate(),
            on_toggle=lambda: self.toggle(),
        )

    def _start_jiggle_loop(self) -> None:
        def loop() -> None:
            while self.enabled and not self._stop_event.is_set():
                try:
                    mouse.jiggle(self.settings.delta_pixels)
                    self.last_jiggle_at = datetime.now()
                    self._refresh_tray()
                except Exception:
                    pass
                interval = max(5.0, float(self.settings.interval_seconds))
                end = time.time() + interval
                while self.enabled and not self._stop_event.is_set() and time.time() < end:
                    time.sleep(0.25)

        threading.Thread(target=loop, daemon=True).start()

    def _start_schedule_loop(self) -> None:
        def loop() -> None:
            while not self._stop_event.is_set():
                self._sync_schedule()
                time.sleep(15)

        threading.Thread(target=loop, daemon=True).start()

    def _sync_schedule(self) -> None:
        schedule = self.settings.schedule
        self.schedule_wants_active = schedule.should_be_active()
        if not schedule.enabled:
            return
        if self.schedule_wants_active and not self.enabled:
            self.activate()
        elif not self.schedule_wants_active and self.enabled:
            self.deactivate()

    def _refresh_tray(self) -> None:
        icon = self._icon
        if icon is None:
            return
        try:
            icon.icon = make_tray_icon(active=self.enabled)
            icon.title = f"Teams Macro — {self.status_line()}"
            icon.menu = self._make_menu()
            icon.update_menu()
        except Exception:
            pass
