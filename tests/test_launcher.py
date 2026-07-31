import unittest

from pipeline.launcher import _launcher_header_height


class LauncherLayoutTests(unittest.TestCase):
    def test_header_expands_when_scaled_fonts_exceed_minimum_height(self):
        self.assertEqual(_launcher_header_height(40, 48), 92)
        self.assertEqual(_launcher_header_height(54, 70), 102)


if __name__ == "__main__":
    unittest.main()
