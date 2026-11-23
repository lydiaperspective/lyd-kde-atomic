# Lyd Atomic

A minimal KDE Plasma workstation built as Fedora Atomic desktop images with BlueBuild.

## Hardware editions

| Edition | Image | Graphics |
|---|---|---|
| NVIDIA | `ghcr.io/lydiaperspective/lyd-atomic-nvidia:latest` | Proprietary NVIDIA 580.x driver included |
| Standard | `ghcr.io/lydiaperspective/lyd-atomic-standard:latest` | Fedora in-kernel graphics stack; no proprietary NVIDIA driver by default |
| Server | `ghcr.io/lydiaperspective/lyd-atomic-server:latest` | Headless Fedora bootc server with Podman, Cockpit, KVM and firewalld |

The Standard edition is intended for Intel and AMD graphics systems, and can also be used on a system with an NVIDIA GPU. To add the proprietary NVIDIA driver after installation, run `lydsetup` and select **NVIDIA proprietary driver**. The installer adds RPM Fusion in one deployment, then layers the driver packages in a second deployment after reboot.

The Standard edition's optional driver installation uses the current RPM Fusion `akmod-nvidia` package. It is not guaranteed to match the NVIDIA edition's prebuilt 580.x driver branch. Secure Boot may require additional module-signing configuration; `lydsetup` warns when it detects Secure Boot and does not enroll keys automatically.

The NVIDIA and Standard editions share the same KDE desktop, Waterfox Flatpak, Mystical theme, lydhelp and lydsetup commands. The Server edition is a separate headless image with server-focused tools and Cockpit.

## Project status

Initial project foundation. Both image builds, ISO installers, update paths, NVIDIA driver operation, rollback and hardware support still require validation in a VM and on physical hardware.

## Technology

BlueBuild creates the Fedora Kinoite-based OCI images. The NVIDIA edition uses BlueBuild's Fedora 45 Kinoite NVIDIA base, which supplies the proprietary 580.x driver. The Standard edition uses the standard Fedora Kinoite base. GitHub Actions builds both editions and publishes them to GHCR. The ISO workflow can convert either published image into an installable ISO.

## Build locally

Install Podman and BlueBuild CLI:

```bash
git clone https://github.com/lydiaperspective/lyd-kde-atomic.git
cd lyd-kde-atomic

# NVIDIA edition
bluebuild generate recipes/lyd-kde.yml -o Containerfile
bluebuild build recipes/lyd-kde.yml

# Standard edition
bluebuild generate recipes/lyd-kde-intel.yml -o Containerfile
bluebuild build recipes/lyd-kde-intel.yml
```

See [docs/BUILDING.md](docs/BUILDING.md) for CI signing setup, Secure Boot and ISO generation.

## GitHub Actions

- Pushes to `main` and manual dispatch build all three editions in parallel.
- Pull requests validate both recipes without publishing.
- The **Build installable ISO** workflow lets you choose NVIDIA, Standard or Server and a published image tag.
- ISO artifacts include SHA256 checksums.

## Shared desktop

- KDE Plasma (Fedora Kinoite 45)
- Waterfox from Flathub (`net.waterfox.waterfox`), configured as the default browser
- Mystical Global Theme, wallpaper, Plasma style, splash and generated icon theme
- Dolphin, Konsole, Kate, Ark, Okular, Spectacle and Discover
- Flatpak support with Flathub, KDE Discover integration and KDE desktop portals
- AppImage support with FUSE 2 compatibility and FUSE 3 runtime support
- Aurorae KWin decoration engine for SVG-based window decoration themes
- `lydhelp` terminal reference and `lydsetup` optional-feature manager

## Server edition

The Server edition is a separate headless Fedora bootc image:

- Podman, Podman Compose, Buildah and Skopeo
- Cockpit web console with system, Podman, virtual-machine, storage, NetworkManager, SELinux and diagnostic modules
- KVM/libvirt virtualization with UEFI firmware, TPM emulation and virtual networking components
- OpenSSH server and client
- firewalld enabled by default
- `lydhelp` and `lydsetup`

Cockpit is enabled through `cockpit.socket` and is available on TCP port 9090. SSH is enabled and allowed on TCP port 22. The default firewalld public zone allows only SSH, Cockpit and DHCPv6 client traffic. It deliberately does not open arbitrary container-published ports: open only the ports required by services you deploy, and prefer limiting them to the relevant network zone or source range.

Podman-published ports are not automatically opened in firewalld. For example, after choosing an application port, add a permanent firewalld rule for that specific TCP or UDP port and reload firewalld. Do not expose libvirt management, VNC or SPICE ports directly to untrusted networks.

Virtualization packages are included and `libvirtd` is enabled. Add the administrative user to the `libvirt` and `kvm` groups with `lydsetup`'s virtualization option if needed; log out and back in for group membership to apply.

Tailscale can be installed on any edition from `lydsetup`. The command adds Tailscale's official Fedora repository, layers its package, and enables `tailscaled` after reboot. Zed can be installed on workstation editions from `lydsetup`; it uses Zed's official per-user Linux installer and does not alter the immutable system deployment.

## Application formats and theming

### Flatpak

Flatpak is installed system-wide, Flathub is configured as a system remote, and KDE Discover's Flatpak backend is included. The KDE desktop portal backend is installed for file pickers, screen sharing and other portal-integrated features. Manage apps graphically through Discover or with `flatpak` commands. Apps installed from Flathub remain separate from the immutable base image.

### AppImage

Both images include FUSE 2 compatibility libraries and FUSE 3 tools/libraries. This supports a broad range of AppImages, including older runtimes that require `libfuse.so.2`. Downloaded AppImages can be made executable in Dolphin or with `chmod +x AppName.AppImage`, then launched directly. `lydhelp appimage` includes basic usage and extraction fallback guidance. Some AppImages still depend on host libraries or runtime assumptions and cannot be guaranteed to work universally.

### Aurorae

The Fedora `aurorae` package is included in both images. It provides KWin's Aurorae SVG-based window-decoration engine, allowing compatible Aurorae decoration themes to be selected in System Settings. It is separate from Plasma Global Themes and does not automatically install additional decoration themes.

## Optional features

Run `lydsetup` as your normal user:

- NVIDIA proprietary driver on the Standard edition (RPM Fusion akmod; Secure Boot may need separate signing configuration)
- Virtualization: QEMU/KVM, libvirt, virt-manager, UEFI firmware, TPM emulation, networking and group membership
- CoolerControl system package and daemon
- TuneD and tuned-ppd (replaces power-profiles-daemon)
- Tailscale VPN client (all editions)
- Zed editor (per-user install on workstation editions)

Optional packages are not included in the base image. Atomic package changes create a new deployment and normally require a reboot. NVIDIA setup takes two package deployments: one to add RPM Fusion, then another to install the driver.

## Commands

- `lydhelp`: topic-based terminal help for files, folders, search, permissions, storage, processes, networking, packages, Flatpak and Atomic deployments.
- `lydsetup`: interactive optional-feature installer.

## Mystical theme

The Mystical theme is maintained in the separate [lyd-kde-themes](https://github.com/lydiaperspective/lyd-kde-themes) repository. Image builds fetch a pinned commit of that repository, so the theme can evolve independently while image builds remain reproducible. It includes the KDE colour scheme, Global Theme, Plasma Style, wallpaper, splash screen, icon artwork and generated scalable icon theme. The visual identity uses midnight plum, amethyst, lavender and restrained antique-gold accents.

## Important

This is an early project. Do not use it as the only operating system on a device until the installer, updates, rollback and hardware support have been tested. Keep independent backups of important data.
