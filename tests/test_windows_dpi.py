import ctypes
import unittest
from unittest.mock import MagicMock, patch

from pipeline import windows_dpi


class WindowsDpiTests(unittest.TestCase):
    def tearDown(self):
        windows_dpi._dpi_mode = None

    def test_prefers_per_monitor_v2(self):
        user32 = MagicMock()
        shcore = MagicMock()
        user32.SetProcessDpiAwarenessContext.return_value = True

        mode = windows_dpi._enable_windows_high_dpi(user32, shcore)

        self.assertEqual(mode, "per-monitor-v2")
        context = user32.SetProcessDpiAwarenessContext.call_args.args[0]
        self.assertEqual(context.value, ctypes.c_void_p(-4).value)
        shcore.SetProcessDpiAwareness.assert_not_called()
        user32.SetProcessDPIAware.assert_not_called()

    def test_falls_back_to_shcore_per_monitor_awareness(self):
        user32 = MagicMock()
        shcore = MagicMock()
        user32.SetProcessDpiAwarenessContext.return_value = False
        shcore.SetProcessDpiAwareness.return_value = 0

        mode = windows_dpi._enable_windows_high_dpi(user32, shcore)

        self.assertEqual(mode, "per-monitor")
        shcore.SetProcessDpiAwareness.assert_called_once_with(2)
        user32.SetProcessDPIAware.assert_not_called()

    def test_falls_back_to_legacy_system_awareness(self):
        user32 = MagicMock()
        shcore = MagicMock()
        user32.SetProcessDpiAwarenessContext.return_value = False
        shcore.SetProcessDpiAwareness.return_value = 1
        user32.SetProcessDPIAware.return_value = True

        mode = windows_dpi._enable_windows_high_dpi(user32, shcore)

        self.assertEqual(mode, "system-aware")
        user32.SetProcessDPIAware.assert_called_once_with()

    def test_public_setup_is_cached_for_the_process(self):
        user32 = MagicMock()
        shcore = MagicMock()
        user32.SetProcessDpiAwarenessContext.return_value = True

        def load_library(name, **_kwargs):
            return user32 if name == "user32" else shcore

        with (
            patch.object(windows_dpi.sys, "platform", "win32"),
            patch.object(
                windows_dpi.ctypes, "WinDLL", side_effect=load_library, create=True
            ) as win_dll,
        ):
            self.assertEqual(windows_dpi.enable_high_dpi(), "per-monitor-v2")
            self.assertEqual(windows_dpi.enable_high_dpi(), "per-monitor-v2")

        self.assertEqual(win_dll.call_count, 2)
        user32.SetProcessDpiAwarenessContext.assert_called_once()

    def test_fixed_tk_geometry_scales_with_display_dpi(self):
        root = MagicMock()
        root.winfo_fpixels.return_value = 144.0

        self.assertEqual(
            windows_dpi.scaled_tk_window_size(root, 560, 480), (840, 720)
        )


if __name__ == "__main__":
    unittest.main()
