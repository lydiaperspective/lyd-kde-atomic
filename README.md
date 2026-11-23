# Lyd KDE Atomic

A minimal KDE Plasma workstation built as Fedora Atomic desktop images with BlueBuild.

## Hardware editions

| Edition | Image | Graphics |
|---|---|---|
| NVIDIA | `ghcr.io/lydiaperspective/lyd-kde-atomic:latest` | Proprietary NVIDIA 580.x driver |
| Intel / generic | `ghcr.io/lydiaperspective/lyd-kde-atomic-intel:latest` | Fedora's in-kernel graphics stack; no proprietary NVIDIA driver |

The Intel edition is intended for Intel-only systems such as Intel iGPU laptops. It also serves as the generic non-NVIDIA edition. It does not layer NVIDIA drivers or NVIDIA kernel modules.

Both editions share the same KDE desktop, Waterfox Flatpak, Mystical theme, lydhelp and lydsetup commands, and optional workstation features.

## Project status

Initial project foundation. Both image builds, ISO installers, update paths, NVIDIA driver operation, rollback and hardware support still require validation in a VM and on physical hardware.

## Technology

BlueBuild creates the Fedora Kinoite-based OCI images. The NVIDIA edition uses BlueBuild's Fedora 45 Kinoite NVIDIA base, which supplies the proprietary 580.x driver. The Intel edition uses the standard Fedora Kinoite base. GitHub Actions builds both editions and publishes them to GHCR. The ISO workflow can convert either published image into an installable ISO.

## Build locally

Install Podman and BlueBuild CLI:

```bash
git clone https://github.com/lydiaperspective/lyd-kde-atomic.git
cd lyd-kde-atomic

# NVIDIA edition
bluebuild generate recipes/lyd-kde.yml -o Containerfile
bluebuild build recipes/lyd-kde.yml

# Intel / generic edition
bluebuild generate recipes/lyd-kde-intel.yml -o Containerfile
bluebuild build recipes/lyd-kde-intel.yml
```

See [docs/BUILDING.md](docs/BUILDING.md) for CI signing setup, Secure Boot and ISO generation.

## GitHub Actions

- Pushes to `main` and manual dispatch build both editions in parallel.
- Pull requests validate both recipes without publishing.
- The **Build installable ISO** workflow lets you choose NVIDIA or Intel and a published image tag.
- ISO artifacts include SHA256 checksums.

## Shared desktop

- KDE Plasma (Fedora Kinoite 45)
- Waterfox from Flathub (`net.waterfox.waterfox`), configured as the default browser
- Mystical Global Theme, wallpaper, Plasma style, splash and generated icon theme
- Dolphin, Konsole, Kate, Ark, Okular, Spectacle and Discover
- Flatpak support with Flathub enabled
- `lydhelp` terminal reference and `lydsetup` optional-feature manager

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

This is an early project. Do not use it as the only operating system on a device until the installer, updates, rollback and hardware support have been tested. Keep independent backups of important data.
