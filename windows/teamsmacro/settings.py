from __future__ import annotations

import json
import os
import sys
from dataclasses import asdict, dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any


def app_data_dir() -> Path:
    if sys.platform == "win32":
        base = Path(os.environ.get("APPDATA", str(Path.home() / "AppData" / "Roaming")))
        path = base / "TeamsMacro"
    else:
        path = Path.home() / ".teamsmacro"
    path.mkdir(parents=True, exist_ok=True)
    return path


def settings_path() -> Path:
    return app_data_dir() / "settings.json"


@dataclass
class ScheduleConfig:
    enabled: bool = True
    start_minutes: int = 9 * 60
    stop_minutes: int = 18 * 60
    lunch_break_enabled: bool = True
    lunch_start_minutes: int = 12 * 60
    lunch_end_minutes: int = 13 * 60 + 30
    # Calendar weekdays: 1=dimanche … 7=samedi (comme macOS)
    excluded_weekdays: list[int] = field(default_factory=lambda: [1, 7])

    def should_be_active(self, when: datetime | None = None) -> bool:
        when = when or datetime.now()
        if not self.enabled:
            return False
        # datetime.weekday(): Monday=0 … Sunday=6 → Calendar: Sunday=1 … Saturday=7
        calendar_weekday = ((when.weekday() + 1) % 7) + 1
        if calendar_weekday in self.excluded_weekdays:
            return False
        minutes = when.hour * 60 + when.minute
        if not self._in_work_window(minutes):
            return False
        if self._in_lunch_break(minutes):
            return False
        return True

    def is_within_lunch_break(self, when: datetime | None = None) -> bool:
        when = when or datetime.now()
        if not self.enabled or not self.lunch_break_enabled:
            return False
        minutes = when.hour * 60 + when.minute
        return self._in_lunch_break(minutes)

    def summary(self) -> str:
        if not self.enabled:
            return "Planification désactivée"
        days = [
            label
            for wid, label in WEEKDAY_SHORT
            if wid not in self.excluded_weekdays
        ]
        days_text = ", ".join(days) if days else "aucun jour"
        text = f"{fmt_minutes(self.start_minutes)} → {fmt_minutes(self.stop_minutes)}"
        if self.lunch_break_enabled:
            text += (
                f" · pause {fmt_minutes(self.lunch_start_minutes)}"
                f"–{fmt_minutes(self.lunch_end_minutes)}"
            )
        return f"{text} · {days_text}"

    def _in_work_window(self, minutes: int) -> bool:
        if self.start_minutes == self.stop_minutes:
            return True
        if self.start_minutes < self.stop_minutes:
            return self.start_minutes <= minutes < self.stop_minutes
        return minutes >= self.start_minutes or minutes < self.stop_minutes

    def _in_lunch_break(self, minutes: int) -> bool:
        if not self.lunch_break_enabled:
            return False
        if self.lunch_start_minutes == self.lunch_end_minutes:
            return False
        if self.lunch_start_minutes < self.lunch_end_minutes:
            return self.lunch_start_minutes <= minutes < self.lunch_end_minutes
        return minutes >= self.lunch_start_minutes or minutes < self.lunch_end_minutes


@dataclass
class AppSettings:
    interval_seconds: float = 240.0
    delta_pixels: int = 1
    launch_at_startup: bool = True
    hotkey_activate: str = ""
    hotkey_deactivate: str = ""
    hotkey_toggle: str = "<ctrl>+<alt>+t"
    schedule: ScheduleConfig = field(default_factory=ScheduleConfig)

    @classmethod
    def load(cls) -> AppSettings:
        path = settings_path()
        if not path.exists():
            settings = cls()
            settings.save()
            return settings
        try:
            raw: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return cls()

        schedule_raw = raw.get("schedule") or {}
        schedule = ScheduleConfig(
            enabled=bool(schedule_raw.get("enabled", True)),
            start_minutes=int(schedule_raw.get("start_minutes", 9 * 60)),
            stop_minutes=int(schedule_raw.get("stop_minutes", 18 * 60)),
            lunch_break_enabled=bool(schedule_raw.get("lunch_break_enabled", True)),
            lunch_start_minutes=int(schedule_raw.get("lunch_start_minutes", 12 * 60)),
            lunch_end_minutes=int(schedule_raw.get("lunch_end_minutes", 13 * 60 + 30)),
            excluded_weekdays=list(
                schedule_raw.get("excluded_weekdays")
                or ScheduleConfig().excluded_weekdays
            ),
        )
        return cls(
            interval_seconds=float(raw.get("interval_seconds", 240)),
            delta_pixels=int(raw.get("delta_pixels", 1)),
            launch_at_startup=bool(raw.get("launch_at_startup", True)),
            hotkey_activate=str(raw.get("hotkey_activate", "")),
            hotkey_deactivate=str(raw.get("hotkey_deactivate", "")),
            hotkey_toggle=str(raw.get("hotkey_toggle", "<ctrl>+<alt>+t")),
            schedule=schedule,
        )

    def save(self) -> None:
        payload = {
            "interval_seconds": self.interval_seconds,
            "delta_pixels": self.delta_pixels,
            "launch_at_startup": self.launch_at_startup,
            "hotkey_activate": self.hotkey_activate,
            "hotkey_deactivate": self.hotkey_deactivate,
            "hotkey_toggle": self.hotkey_toggle,
            "schedule": asdict(self.schedule),
        }
        settings_path().write_text(
            json.dumps(payload, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )


WEEKDAY_OPTIONS: list[tuple[int, str]] = [
    (2, "Lundi"),
    (3, "Mardi"),
    (4, "Mercredi"),
    (5, "Jeudi"),
    (6, "Vendredi"),
    (7, "Samedi"),
    (1, "Dimanche"),
]

WEEKDAY_SHORT: list[tuple[int, str]] = [
    (2, "lun."),
    (3, "mar."),
    (4, "mer."),
    (5, "jeu."),
    (6, "ven."),
    (7, "sam."),
    (1, "dim."),
]


def fmt_minutes(value: int) -> str:
    value = max(0, min(value, 24 * 60 - 1))
    return f"{value // 60:02d}:{value % 60:02d}"


def minutes_from_hhmm(text: str, fallback: int) -> int:
    try:
        parts = text.strip().split(":")
        hour = int(parts[0])
        minute = int(parts[1]) if len(parts) > 1 else 0
        if not (0 <= hour <= 23 and 0 <= minute <= 59):
            return fallback
        return hour * 60 + minute
    except (ValueError, IndexError):
        return fallback
