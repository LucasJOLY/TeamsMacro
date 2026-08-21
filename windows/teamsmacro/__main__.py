from __future__ import annotations

import sys


def main() -> None:
    if sys.platform != "win32":
        print("Cette version est destinée à Windows. Sur macOS, utilise le dossier racine (make run).")
        sys.exit(1)

    from teamsmacro.app import TeamsMacroApp

    TeamsMacroApp().run()


if __name__ == "__main__":
    main()
