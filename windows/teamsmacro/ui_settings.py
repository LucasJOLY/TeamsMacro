from __future__ import annotations

import tkinter as tk
from tkinter import messagebox, ttk
from typing import Callable

from teamsmacro.settings import (
    WEEKDAY_OPTIONS,
    AppSettings,
    fmt_minutes,
    minutes_from_hhmm,
)


class SettingsWindow:
    def __init__(self, settings: AppSettings, on_save: Callable[[AppSettings], None]) -> None:
        self._settings = settings
        self._on_save = on_save
        self._root = tk.Tk()
        self._root.title("Teams Macro — Réglages")
        self._root.geometry("480x560")
        self._root.minsize(440, 520)

        notebook = ttk.Notebook(self._root)
        notebook.pack(fill="both", expand=True, padx=10, pady=10)

        general = ttk.Frame(notebook, padding=12)
        schedule = ttk.Frame(notebook, padding=12)
        shortcuts = ttk.Frame(notebook, padding=12)
        notebook.add(general, text="Général")
        notebook.add(schedule, text="Planning")
        notebook.add(shortcuts, text="Raccourcis")

        self._build_general(general)
        self._build_schedule(schedule)
        self._build_shortcuts(shortcuts)

        buttons = ttk.Frame(self._root, padding=(10, 0, 10, 10))
        buttons.pack(fill="x")
        ttk.Button(buttons, text="Enregistrer", command=self._save).pack(side="right")
        ttk.Button(buttons, text="Annuler", command=self._root.destroy).pack(
            side="right", padx=(0, 8)
        )

        self._root.protocol("WM_DELETE_WINDOW", self._root.destroy)

    def run(self) -> None:
        self._root.mainloop()

    def _build_general(self, parent: ttk.Frame) -> None:
        ttk.Label(parent, text="Comportement", font=("", 11, "bold")).grid(
            row=0, column=0, columnspan=2, sticky="w", pady=(0, 8)
        )

        ttk.Label(parent, text="Intervalle (secondes)").grid(row=1, column=0, sticky="w")
        self.interval_var = tk.StringVar(value=str(self._settings.interval_seconds))
        ttk.Entry(parent, textvariable=self.interval_var, width=12).grid(
            row=1, column=1, sticky="e", pady=4
        )

        ttk.Label(parent, text="Amplitude (pixels)").grid(row=2, column=0, sticky="w")
        self.delta_var = tk.StringVar(value=str(self._settings.delta_pixels))
        ttk.Entry(parent, textvariable=self.delta_var, width=12).grid(
            row=2, column=1, sticky="e", pady=4
        )

        ttk.Label(
            parent,
            text="Un déplacement minime suffit pour Teams. 240 s est un bon défaut.",
            wraplength=400,
        ).grid(row=3, column=0, columnspan=2, sticky="w", pady=(8, 16))

        ttk.Label(parent, text="Démarrage", font=("", 11, "bold")).grid(
            row=4, column=0, columnspan=2, sticky="w", pady=(0, 8)
        )
        self.startup_var = tk.BooleanVar(value=self._settings.launch_at_startup)
        ttk.Checkbutton(
            parent,
            text="Lancer au démarrage de Windows",
            variable=self.startup_var,
        ).grid(row=5, column=0, columnspan=2, sticky="w")

        parent.columnconfigure(0, weight=1)

    def _build_schedule(self, parent: ttk.Frame) -> None:
        s = self._settings.schedule
        self.schedule_enabled = tk.BooleanVar(value=s.enabled)
        ttk.Checkbutton(
            parent,
            text="Activer la planification",
            variable=self.schedule_enabled,
        ).grid(row=0, column=0, columnspan=2, sticky="w", pady=(0, 12))

        ttk.Label(parent, text="Démarrer à (HH:MM)").grid(row=1, column=0, sticky="w")
        self.start_var = tk.StringVar(value=fmt_minutes(s.start_minutes))
        ttk.Entry(parent, textvariable=self.start_var, width=10).grid(
            row=1, column=1, sticky="e", pady=4
        )

        ttk.Label(parent, text="Arrêter à (HH:MM)").grid(row=2, column=0, sticky="w")
        self.stop_var = tk.StringVar(value=fmt_minutes(s.stop_minutes))
        ttk.Entry(parent, textvariable=self.stop_var, width=10).grid(
            row=2, column=1, sticky="e", pady=4
        )

        self.lunch_enabled = tk.BooleanVar(value=s.lunch_break_enabled)
        ttk.Checkbutton(
            parent, text="Pause midi", variable=self.lunch_enabled
        ).grid(row=3, column=0, columnspan=2, sticky="w", pady=(12, 4))

        ttk.Label(parent, text="Début pause (HH:MM)").grid(row=4, column=0, sticky="w")
        self.lunch_start_var = tk.StringVar(value=fmt_minutes(s.lunch_start_minutes))
        ttk.Entry(parent, textvariable=self.lunch_start_var, width=10).grid(
            row=4, column=1, sticky="e", pady=4
        )

        ttk.Label(parent, text="Fin pause (HH:MM)").grid(row=5, column=0, sticky="w")
        self.lunch_end_var = tk.StringVar(value=fmt_minutes(s.lunch_end_minutes))
        ttk.Entry(parent, textvariable=self.lunch_end_var, width=10).grid(
            row=5, column=1, sticky="e", pady=4
        )

        ttk.Label(parent, text="Jours exclus", font=("", 11, "bold")).grid(
            row=6, column=0, columnspan=2, sticky="w", pady=(16, 8)
        )

        self.day_vars: dict[int, tk.BooleanVar] = {}
        for index, (day_id, label) in enumerate(WEEKDAY_OPTIONS):
            var = tk.BooleanVar(value=day_id in s.excluded_weekdays)
            self.day_vars[day_id] = var
            ttk.Checkbutton(parent, text=label, variable=var).grid(
                row=7 + index, column=0, sticky="w"
            )

        parent.columnconfigure(0, weight=1)

    def _build_shortcuts(self, parent: ttk.Frame) -> None:
        ttk.Label(
            parent,
            text="Format pynput, ex. <ctrl>+<alt>+t ou <ctrl>+<shift>+a",
            wraplength=400,
        ).grid(row=0, column=0, columnspan=2, sticky="w", pady=(0, 12))

        ttk.Label(parent, text="Activer").grid(row=1, column=0, sticky="w")
        self.hk_activate = tk.StringVar(value=self._settings.hotkey_activate)
        ttk.Entry(parent, textvariable=self.hk_activate, width=28).grid(
            row=1, column=1, sticky="e", pady=4
        )

        ttk.Label(parent, text="Désactiver").grid(row=2, column=0, sticky="w")
        self.hk_deactivate = tk.StringVar(value=self._settings.hotkey_deactivate)
        ttk.Entry(parent, textvariable=self.hk_deactivate, width=28).grid(
            row=2, column=1, sticky="e", pady=4
        )

        ttk.Label(parent, text="Basculer").grid(row=3, column=0, sticky="w")
        self.hk_toggle = tk.StringVar(value=self._settings.hotkey_toggle)
        ttk.Entry(parent, textvariable=self.hk_toggle, width=28).grid(
            row=3, column=1, sticky="e", pady=4
        )

        parent.columnconfigure(0, weight=1)

    def _save(self) -> None:
        try:
            interval = float(self.interval_var.get().replace(",", "."))
            delta = int(self.delta_var.get())
            if interval <= 0 or delta <= 0:
                raise ValueError
        except ValueError:
            messagebox.showerror(
                "Teams Macro",
                "Intervalle et amplitude doivent être des nombres positifs.",
                parent=self._root,
            )
            return

        schedule = self._settings.schedule
        schedule.enabled = self.schedule_enabled.get()
        schedule.start_minutes = minutes_from_hhmm(
            self.start_var.get(), schedule.start_minutes
        )
        schedule.stop_minutes = minutes_from_hhmm(
            self.stop_var.get(), schedule.stop_minutes
        )
        schedule.lunch_break_enabled = self.lunch_enabled.get()
        schedule.lunch_start_minutes = minutes_from_hhmm(
            self.lunch_start_var.get(), schedule.lunch_start_minutes
        )
        schedule.lunch_end_minutes = minutes_from_hhmm(
            self.lunch_end_var.get(), schedule.lunch_end_minutes
        )
        schedule.excluded_weekdays = [
            day_id for day_id, var in self.day_vars.items() if var.get()
        ]

        self._settings.interval_seconds = interval
        self._settings.delta_pixels = delta
        self._settings.launch_at_startup = self.startup_var.get()
        self._settings.hotkey_activate = self.hk_activate.get().strip()
        self._settings.hotkey_deactivate = self.hk_deactivate.get().strip()
        self._settings.hotkey_toggle = self.hk_toggle.get().strip()
        self._settings.schedule = schedule
        self._settings.save()
        self._on_save(self._settings)
        self._root.destroy()
