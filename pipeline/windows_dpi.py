"""Windows high-DPI setup for Tk windows and native file dialogs."""

from __future__ import annotations

import ctypes
import sys
import threading
from typing import Any


_PER_MONITOR_AWARE_V2 = -4
_dpi_mode: str | None = None
_dpi_lock = threading.Lock()


def _configure_function(function: Any, argtypes: list[Any], restype: Any) -> None:
    """Set ctypes signatures while remaining friendly to mocked callables."""
    function.argtypes = argtypes
    function.restype = restype


def _enable_windows_high_dpi(user32: Any, shcore: Any | None) -> str:
    """Try the newest DPI API first, with fallbacks for older Windows versions."""
    try:
        set_context = user32.SetProcessDpiAwarenessContext
        _configure_function(set_context, [ctypes.c_void_p], ctypes.c_bool)
        if set_context(ctypes.c_void_p(_PER_MONITOR_AWARE_V2)):
            return "per-monitor-v2"
    except (AttributeError, OSError):
        pass

    if shcore is not None:
        try:
            set_awareness = shcore.SetProcessDpiAwareness
            _configure_function(set_awareness, [ctypes.c_int], ctypes.c_long)
            if set_awareness(2) == 0:
                return "per-monitor"
        except (AttributeError, OSError):
            pass

    try:
        set_aware = user32.SetProcessDPIAware
        _configure_function(set_aware, [], ctypes.c_bool)
        if set_aware():
            return "system-aware"
    except (AttributeError, OSError):
        pass
    return "unchanged"


def enable_high_dpi() -> str:
    """Enable the best process DPI mode available; safe to call repeatedly."""
    global _dpi_mode
    with _dpi_lock:
        if _dpi_mode is not None:
            return _dpi_mode
        if sys.platform != "win32":
            _dpi_mode = "unsupported"
            return _dpi_mode
        try:
            user32 = ctypes.WinDLL("user32", use_last_error=True)
        except (AttributeError, OSError):
            _dpi_mode = "unchanged"
            return _dpi_mode
        try:
            shcore = ctypes.WinDLL("shcore", use_last_error=True)
        except (AttributeError, OSError):
            shcore = None
        _dpi_mode = _enable_windows_high_dpi(user32, shcore)
        return _dpi_mode


def scaled_tk_window_size(root: Any, width: int, height: int) -> tuple[int, int]:
    """Scale a fixed Tk geometry so high-DPI fonts retain the intended space."""
    try:
        scale = max(1.0, min(3.0, float(root.winfo_fpixels("1i")) / 96.0))
    except (AttributeError, TypeError, ValueError):
        scale = 1.0
    return round(width * scale), round(height * scale)
