"""Category for the Lyd Atomic edition selector."""

from pyanaconda.ui.categories import SpokeCategory


class LydAtomicCategory(SpokeCategory):
    """Group the Lyd Atomic edition selection spoke."""

    @staticmethod
    def get_title():
        return "LYD ATOMIC"

    @staticmethod
    def get_sort_order():
        return 0
