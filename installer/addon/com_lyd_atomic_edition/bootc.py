"""Helpers for keeping the selected bootc image in Anaconda Kickstart data."""

from pykickstart.commands.bootc import F45_Bootc


def set_bootc_image(data, image):
    """Set the bootc source and update references on Anaconda Kickstart data.

    Some installer startup paths do not expose the interactive-defaults.ks
    bootc command on the UI data object. Create the Fedora 45 pykickstart
    command in that case so the standard Anaconda bootc installation path
    still receives a proper command object.
    """
    command = getattr(data, "bootc", None)
    if command is None:
        command = F45_Bootc()
        command.seen = True
        data.bootc = command

    command.sourceImgRef = "registry:" + image
    command.targetImgRef = image
    command.seen = True
    return command
