# Lyd Atomic

A modular Fedora bootc / KDE Plasma operating system built with BlueBuild.

## Published images

| Image | Purpose |
|---|---|
| `ghcr.io/lydiaperspective/lyd-atomic-base:latest` | Shared KDE workstation base: Waterfox, SyncThingy, printing and scanning |
| `ghcr.io/lydiaperspective/lyd-atomic-nvidia:latest` | Shared workstation base with the proprietary NVIDIA 580 driver |
| `ghcr.io/lydiaperspective/lyd-atomic-nvidia-open:latest` | Shared workstation base with the current NVIDIA open kernel module driver |
| `ghcr.io/lydiaperspective/lyd-atomic-workstation:latest` | Final standard-graphics workstation with virtualization, development tools and Mystical theme |
| `ghcr.io/lydiaperspective/lyd-atomic-nvidia-gaming:latest` | Final NVIDIA 580 gaming workstation with Steam, gaming launchers, virtualization, development tools and Mystical theme |
| `ghcr.io/lydiaperspective/lyd-atomic-steamdeck:latest` | Steam Deck LCD image with Steam Gaming Mode (Gamescope), based on Bazzite Deck |
| `ghcr.io/lydiaperspective/lyd-atomic-server:latest` | Headless server with Podman, Cockpit, KVM/libvirt and firewalld |

The two final desktop editions share their package and feature definitions. The standard edition derives from the single `lyd-atomic-base`; the NVIDIA gaming edition derives from the NVIDIA 580 base. The NVIDIA open image is also published as a driver-specific workstation base for users who need the newer open kernel module branch.

## Modular build layout

BlueBuild recipes use reusable files under `recipes/`:

- `workstation-base.yml` — KDE applications, core utilities, printing/scanning, Waterfox, SyncThingy and shared system files.
- `feature-virtualization.yml` — QEMU/KVM, libvirt, virt-manager and libvirt service.
- `feature-development.yml` — Distrobox, Podman and Podman Compose. Zed can be installed per-user with its official installer.
- `feature-steam.yml` — native Steam, Steam device support, GameMode, MangoHud, Gamescope and the Lyd Gamescope session.
- `feature-gaming.yml` — Protontricks, ProtonPlus, Lutris and Heroic Flatpaks.
- `feature-mystic.yml` — the pinned Mystical KDE theme and coordinated boot assets.

These are reusable BlueBuild module fragments, not independently merged OCI images. OCI images have one parent image; the final recipes compose the reusable modules at build time. This keeps the build chain explicit and avoids fragile image-merging tricks.

## Desktop contents

The shared workstation base includes KDE Plasma and common KDE applications, Discover/Flatpak integration, FUSE 2 and FUSE 3 support for AppImages, Breeze icons, Waterfox, SyncThingy, CUPS, SANE, AirScan, IPP-over-USB, Avahi and Skanpage. CUPS and Avahi are enabled by default.

The complete workstation adds virtualization, development packages and the Mystical theme. The NVIDIA gaming workstation adds those same features plus the NVIDIA 580 driver, native Steam, GameMode, MangoHud, Gamescope, Protontricks, ProtonPlus, Lutris and Heroic.

## Server

The server image is independent of the KDE workstation chain. It includes rootless-container tooling, Cockpit, SSH, firewalld and KVM/libvirt. Cockpit is enabled on TCP 9090; SSH is enabled on TCP 22. Container-published ports are not opened automatically.

## Build and installer

Pushes to `main` build the reusable base/driver/server images first, then build the final desktop editions and Steam Deck image. Pull requests build the independent component recipes for validation. See [docs/BUILDING.md](docs/BUILDING.md) for local build commands and CI details.

The unified Anaconda installer offers KDE Workstation, NVIDIA Gaming Workstation, Server, HTPC (Plasma Bigscreen) and Steam Deck. It downloads the selected bootc image from GHCR during installation, so an internet connection is required. The installer defaults to the workstation image and uses Btrfs as its default filesystem selection.

## Management commands

- `lydmanage switch workstation` — switch to the standard workstation image.
- `lydmanage switch nvidia-gaming` — switch to the NVIDIA gaming workstation.
- `lydmanage switch server` — switch to the headless server.
- `lydmanage switch <newImage>` — switch to any supported bootc OCI image reference.
- `lydmanage update` — run `bootc update` and stage the latest image.
- `lydmanage status` — show current, staged and rollback deployments.
- `lydmanage rollback` — stage the previous deployment.
- `lydmanage flatpak update` and `lydmanage firmware update` — update applications and supported firmware.
- `lydmanage updates auto enable|disable|status` — manage the weekly update timer.
- `lydm` — short alias for `lydmanage`.
- `lydhelp` — topic-based Linux and Lyd Atomic command reference.
- `lydhelp manage` — built-in reference for the management commands.

## Project status

This is an actively developed project. Image builds, installer paths, driver operation, updates, rollback and hardware support must be validated in virtual machines and on physical hardware before relying on the system. Keep independent backups of important data.
