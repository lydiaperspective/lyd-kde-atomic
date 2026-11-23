# Lyd KDE Atomic

A minimal KDE Plasma workstation built as a Fedora Atomic desktop image with BlueBuild.

## Goals

- One initial x86_64 workstation image based on Fedora Kinoite 45.
- A slim KDE Plasma desktop with a small set of essential KDE applications.
- Proprietary NVIDIA 580.x driver with a prebuilt kernel module.
- Waterfox Flatpak as the default and only preinstalled web browser.
- The Lyd Ark Mystical KDE appearance.
- `lydhelp` terminal reference and `lydsetup` optional-feature manager.
- Local builds and GitHub Actions image/ISO builds.

## Project status

Initial project foundation. The first image, NVIDIA module, ISO installer, update path and rollback flow still require validation in a VM and on physical hardware.

## Technology

BlueBuild creates the Fedora Kinoite-based OCI image. The image uses BlueBuild's Fedora 45 Kinoite NVIDIA base, which supplies the proprietary 580.x driver. GitHub Actions publishes the custom image to GHCR. The separate ISO workflow uses bootc-image-builder to create an installable ISO from a published image.

## Build locally

Install Podman and BlueBuild CLI:

```bash
git clone https://github.com/lydiaperspective/lyd-kde-atomic.git
cd lyd-kde-atomic
bluebuild generate recipes/lyd-kde.yml -o Containerfile
bluebuild build recipes/lyd-kde.yml
```

See [docs/BUILDING.md](docs/BUILDING.md) for CI signing setup, Secure Boot and ISO generation.

## GitHub Actions

- Pushes to `main` and manual dispatch build and publish the image to GHCR.
- Pull requests build without publishing.
- The **Build installable ISO** workflow can be run manually after an image is published.
- ISO artifacts include SHA256 checksums.

Image: `ghcr.io/lydiaperspective/lyd-kde-atomic:latest`.

## Default desktop

- KDE Plasma (Fedora Kinoite 45)
- Waterfox from Flathub (`net.waterfox.waterfox`)
- Mystical Global Theme, wallpaper, Plasma style, splash and generated icon theme
- Dolphin, Konsole, Kate, Ark, Okular, Spectacle and Discover
- Flatpak support with Flathub enabled
- Proprietary NVIDIA 580.x driver

## Optional features

Run `lydsetup` as your normal user:

- Virtualization: QEMU/KVM, libvirt, virt-manager, UEFI firmware, TPM emulation, networking and group membership
- CoolerControl system package and daemon
- TuneD and tuned-ppd (replaces power-profiles-daemon)

Optional packages are not included in the base image. Atomic package changes create a new deployment and normally require a reboot.

## Commands

- `lydhelp`: topic-based terminal help for files, folders, search, permissions, storage, processes, networking, packages, Flatpak and Atomic deployments.
- `lydsetup`: interactive optional-feature installer.

## Mystical theme

The theme is sourced from [lyd-kde-deb-live](https://github.com/lydiaperspective/lyd-kde-deb-live) at a pinned commit and installs the KDE colour scheme, Global Theme, Plasma Style, wallpaper and generated scalable icon theme. The visual identity uses midnight plum, amethyst, lavender and restrained antique-gold accents.

## Important

This is an early project. Do not use it as the only operating system on a device until the ISO installer, NVIDIA driver, updates, rollback and hardware support have been tested. Keep independent backups of important data.
