from __future__ import annotations

import ctypes
from ctypes import wintypes


INPUT_MOUSE = 0
MOUSEEVENTF_MOVE = 0x0001


class MOUSEINPUT(ctypes.Structure):
    _fields_ = [
        ("dx", wintypes.LONG),
        ("dy", wintypes.LONG),
        ("mouseData", wintypes.DWORD),
        ("dwFlags", wintypes.DWORD),
        ("time", wintypes.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]


class INPUT(ctypes.Structure):
    class _INPUT(ctypes.Union):
        _fields_ = [("mi", MOUSEINPUT)]

    _anonymous_ = ("_input",)
    _fields_ = [
        ("type", wintypes.DWORD),
        ("_input", _INPUT),
    ]


def jiggle(delta: int = 1) -> None:
    delta = max(1, int(delta))
    _move(delta, 0)
    _move(-delta, 0)


def _move(dx: int, dy: int) -> None:
    extra = ctypes.c_ulong(0)
    event = INPUT(
        type=INPUT_MOUSE,
        mi=MOUSEINPUT(dx, dy, 0, MOUSEEVENTF_MOVE, 0, ctypes.pointer(extra)),
    )
    ctypes.windll.user32.SendInput(1, ctypes.byref(event), ctypes.sizeof(event))
