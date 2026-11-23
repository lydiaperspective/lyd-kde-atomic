# Lyd KDE Atomic

A minimal KDE Plasma workstation built as a Fedora Atomic desktop image with BlueBuild.

## Goals

- One initial x86_64 workstation image.
- KDE Plasma with a restrained base package set.
- Proprietary NVIDIA 580-series driver target.
- Waterfox Flatpak as the default and only preinstalled browser.
- The Lyd Ark Mystical KDE appearance.
- `lydhelp` terminal reference and `lydsetup` optional-feature manager.
- Local builds and GitHub Actions image/ISO builds.

## Project status

The repository is being initialized. The initial image and installer must be validated in a VM and on supported hardware before being treated as a production operating system. NVIDIA 580 compatibility is a hard requirement and must be verified against the Fedora release and kernel selected by the build.

## Technology

The project uses BlueBuild recipes to create a bootable Fedora Atomic image. The image is published to GitHub Container Registry and can be rebased onto using bootc-compatible tooling. An ISO is generated from the published image using bootc-image-builder in GitHub Actions.

## Build locally

Requirements: Fedora or another supported Linux build host, Podman (or Docker), and BlueBuild CLI.

```bash
git clone https://github.com/lydiaperspective/lyd-kde-atomic.git
cd lyd-kde-atomic
bluebuild generate recipes/lyd-kde.yml -o Containerfile
bluebuild build recipes/lyd-kde.yml
```

See [docs/BUILDING.md](docs/BUILDING.md) for local image builds and ISO generation.

## GitHub Actions

- Pushes and manual dispatch build and publish the workstation OCI image to GHCR.
- A separate manual workflow builds an installable ISO from the published image.
- Pull requests validate the recipe without publishing.
- Release and update artifacts include SHA256 checksums.

The image name is `ghcr.io/lydiaperspective/lyd-kde-atomic:latest`.

## Default desktop

- KDE Plasma (Kinoite base)
- Waterfox from Flathub (`net.waterfox.waterfox`) as the only preinstalled browser
- Mystical Global Theme, wallpaper, Plasma style, splash and generated icon theme
- Konsole, Dolphin, Kate, Ark, Okular, Spectacle and Discover
- Flatpak support with Flathub enabled

## Optional features

Run `lydsetup` as your normal user to select optional system features:

- Virtualization: QEMU/KVM, libvirt, virt-manager, firmware, TPM emulation and required services/groups
- Steam system package (RPM Fusion)
- CoolerControl system package and daemon
- TuneD and tuned-ppd (replaces power-profiles-daemon)

These features are opt-in and are not part of the default image. Atomic package changes are staged as a new deployment and require a reboot. Some features may require an additional repository; the setup manager explains this before making changes.

## Commands

- `lydhelp`: topic-based terminal help for files, folders, search, permissions, storage, processes, networking, packages and archives.
- `lydsetup`: interactive optional-feature installer for the workstation.

## Theme source

The Mystical theme is adapted from [lyd-kde-deb-live](https://github.com/lydiaperspective/lyd-kde-deb-live), under its repository license. The theme keeps Breeze-compatible layout and uses midnight plum, amethyst, lavender and restrained antique-gold accents.

## Important

This is an early project. Do not use it as the only operating system on a device until the ISO installer, image updates, NVIDIA driver, rollback path and hardware support have been tested. Keep independent backups of important data.
