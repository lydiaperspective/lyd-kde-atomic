"""Graphical edition selector for Lyd Atomic."""

from pyanaconda.ui.gui.spokes import NormalSpoke

from com_lyd_atomic_edition.bootc import set_bootc_image
from com_lyd_atomic_edition.categories.lyd_atomic import LydAtomicCategory

EDITIONS = {
    "workstation": (
        "ghcr.io/lydiaperspective/lyd-atomic-workstation:latest",
        "KDE Workstation",
    ),
    "nvidia-gaming": (
        "ghcr.io/lydiaperspective/lyd-atomic-nvidia-gaming:latest",
        "NVIDIA Gaming Workstation",
    ),
    "server": (
        "ghcr.io/lydiaperspective/lyd-atomic-server:latest",
        "Server",
    ),
}


class LydAtomicEditionSpoke(NormalSpoke):
    """Choose which Lyd Atomic bootc image Anaconda installs."""

    builderObjects = ["editionSpokeWindow"]
    mainWidgetName = "editionSpokeWindow"
    uiFile = "edition.glade"
    category = LydAtomicCategory
    icon = "computer-symbolic"
    title = "Lyd Atomic Edition"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._edition = None

    def initialize(self):
        super().initialize()
        self._selector = self.builder.get_object("editionSelector")
        for edition, (_, label) in EDITIONS.items():
            self._selector.append(edition, label)
        self._selector.connect("changed", self._on_edition_changed)

    def _on_edition_changed(self, selector):
        selected = selector.get_active_id()
        if selected not in EDITIONS:
            return
        self._edition = selected
        set_bootc_image(self.data, EDITIONS[selected][0], self.payload)

    def refresh(self):
        bootc_data = getattr(self.data, "bootc", None)
        source = getattr(bootc_data, "sourceImgRef", "") if bootc_data else ""
        selected = next(
            (key for key, (image, _) in EDITIONS.items()
             if source in (image, "registry:" + image)),
            "workstation",
        )
        self._selector.set_active_id(selected)
        self._edition = selected

    def apply(self):
        self._edition = self._selector.get_active_id()
        if self._edition not in EDITIONS:
            return
        set_bootc_image(self.data, EDITIONS[self._edition][0], self.payload)

    def execute(self):
        pass

    def on_info_bar_clicked(self, *args):
        """Handle the standard Anaconda spoke info-bar signal."""
        return

    @property
    def ready(self):
        return True

    @property
    def completed(self):
        return self._edition in EDITIONS

    @property
    def mandatory(self):
        return True

    @property
    def status(self):
        if self._edition not in EDITIONS:
            return "Choose an edition"
        return EDITIONS[self._edition][1]
