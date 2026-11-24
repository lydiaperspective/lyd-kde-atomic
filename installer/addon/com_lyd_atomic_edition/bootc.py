"""Helpers for keeping the selected bootc image in Anaconda's configuration."""

from pykickstart.commands.bootc import F45_Bootc
from pyanaconda.modules.common.structures.bootc import BootcConfigurationData


def set_bootc_image(data, image, payload=None):
    """Update both Kickstart data and the active Anaconda bootc source.

    Anaconda processes the Kickstart bootc command into a separate payload
    source configuration before the edition spoke is displayed. Updating only
    data.bootc leaves that already-created payload source pointing at the
    default image, so update both representations.
    """
    source_ref = "registry:" + image

    command = getattr(data, "bootc", None)
    if command is None:
        command = F45_Bootc()
        command.seen = True
        data.bootc = command

    command.sourceImgRef = source_ref
    command.targetImgRef = image
    command.seen = True

    if payload is not None:
        source_proxy = payload.get_source_proxy()
        configuration = BootcConfigurationData.from_structure(
            source_proxy.Configuration
        )
        configuration.sourceImgRef = source_ref
        configuration.targetImgRef = image
        source_proxy.Configuration = BootcConfigurationData.to_structure(
            configuration
        )

    return command
