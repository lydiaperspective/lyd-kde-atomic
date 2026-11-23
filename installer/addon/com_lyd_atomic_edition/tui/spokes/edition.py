"""Text-mode edition selector for Lyd Atomic."""

from simpleline.render.prompt import Prompt
from simpleline.render.screen import InputState
from simpleline.render.containers import ListColumnContainer
from simpleline.render.widgets import CheckboxWidget, TextWidget

from pyanaconda.ui.tui.spokes import NormalTUISpoke

from com_lyd_atomic_edition.categories.lyd_atomic import LydAtomicCategory

EDITIONS = {
    "1": (
        "standard",
        "ghcr.io/lydiaperspective/lyd-atomic-standard:latest",
        "Standard KDE",
    ),
    "2": (
        "nvidia",
        "ghcr.io/lydiaperspective/lyd-atomic-nvidia:latest",
        "NVIDIA KDE",
    ),
    "3": (
        "server",
        "ghcr.io/lydiaperspective/lyd-atomic-server:latest",
        "Server",
    ),
}


class LydAtomicEditionTUISpoke(NormalTUISpoke):
    """Choose the bootc image when Anaconda runs in text mode."""

    category = LydAtomicCategory

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.title = "Lyd Atomic Edition"
        self._selected = "standard"
        self._container = None

    def setup(self, args=None):
        super().setup(args)
        bootc_data = getattr(self.data, "bootc", None)
        source = getattr(bootc_data, "sourceImgRef", "") if bootc_data else ""
        for _, (key, image, _) in EDITIONS.items():
            if source in (image, "registry:" + image):
                self._selected = key
                break
        return True

    def refresh(self, args=None):
        super().refresh(args)
        self._container = ListColumnContainer(columns=1)
        self.window.add_with_separator(TextWidget(
            "Select the operating system image to install. "
            "An internet connection is required to download it from GHCR."
        ))

        for number, (key, image, label) in EDITIONS.items():
            self._container.add(
                CheckboxWidget(
                    title="{}. {} ({})".format(number, label, image),
                    completed=self._selected == key,
                ),
                callback=lambda data, selected=key: self._select(selected),
            )

        self.window.add_with_separator(self._container)
        self.window.add_with_separator(TextWidget(
            "Enter 1, 2, or 3 to change the selection, then press c to continue."
        ))

    def _select(self, selected):
        self._selected = selected

    def input(self, args, key):
        if self._container.process_user_input(key):
            return InputState.PROCESSED_AND_REDRAW

        choice = key.strip()
        if choice in EDITIONS:
            self._selected = EDITIONS[choice][0]
            return InputState.PROCESSED_AND_REDRAW

        if choice.lower() == Prompt.CONTINUE:
            self.apply()
            self.execute()
            return InputState.PROCESSED_AND_CLOSE

        return super().input(args, key)

    def apply(self):
        if self._selected not in {entry[0] for entry in EDITIONS.values()}:
            raise ValueError("A Lyd Atomic edition must be selected")

        bootc_data = getattr(self.data, "bootc", None)
        if bootc_data is None:
            raise RuntimeError("The installer bootc Kickstart command is missing")

        image = next(
            image for _, (key, image, _) in EDITIONS.items()
            if key == self._selected
        )
        bootc_data.sourceImgRef = "registry:" + image
        bootc_data.targetImgRef = image

    def execute(self):
        pass

    @property
    def completed(self):
        return self._selected in {entry[0] for entry in EDITIONS.values()}

    @property
    def mandatory(self):
        return True

    @property
    def status(self):
        return next(
            label for _, (key, _, label) in EDITIONS.items()
            if key == self._selected
        )
