# Building Lyd Atomic

## Image architecture

The project uses one shared KDE workstation base and reusable BlueBuild module fragments. OCI images have one parent image, so the feature sets are composed into the final recipes during the build rather than attempting to merge several unrelated OCI images.

Reusable definitions:

- `recipes/workstation-base.yml` — common KDE workstation packages, Waterfox, SyncThingy and printing/scanning.
- `recipes/feature-virtualization.yml` — QEMU/KVM and libvirt.
- `recipes/feature-development.yml` — Distrobox, Podman and Podman Compose.
- `recipes/feature-steam.yml` — native Steam, Steam device support, GameMode, MangoHud and Gamescope.
- `recipes/feature-gaming.yml` — Protontricks, ProtonPlus, Lutris and Heroic.
- `recipes/feature-mystic.yml` — Mystical KDE theme and boot artwork.

## Build component images

Install Podman and the BlueBuild CLI, then run from the repository root.

### Shared workstation base

```bash
bluebuild generate recipes/lyd-atomic-base.yml -o Containerfile
bluebuild build recipes/lyd-atomic-base.yml
```

Published as `ghcr.io/lydiaperspective/lyd-atomic-base:latest`.

### NVIDIA driver bases

The proprietary image uses BlueBuild's Fedora Kinoite NVIDIA base with the 580.x driver branch:

```bash
bluebuild generate recipes/lyd-atomic-nvidia.yml -o Containerfile
bluebuild build recipes/lyd-atomic-nvidia.yml
```

The current open kernel module branch is built separately:

```bash
bluebuild generate recipes/lyd-atomic-nvidia-open.yml -o Containerfile
bluebuild build recipes/lyd-atomic-nvidia-open.yml
```

Both driver bases reuse the same `workstation-base.yml` module file. The open driver branch supports newer NVIDIA hardware; the proprietary 580 branch is retained for supported older cards. Check the upstream BlueBuild base-image release and GPU support before choosing a driver.

### Final workstation editions

Build these after their parent images have been published:

```bash
bluebuild generate recipes/lyd-atomic-workstation.yml -o Containerfile
bluebuild build recipes/lyd-atomic-workstation.yml

bluebuild generate recipes/lyd-atomic-nvidia-gaming.yml -o Containerfile
bluebuild build recipes/lyd-atomic-nvidia-gaming.yml
```

Published final images:

- `ghcr.io/lydiaperspective/lyd-atomic-workstation:latest`
- `ghcr.io/lydiaperspective/lyd-atomic-nvidia-gaming:latest`

The standard workstation is derived from `lyd-atomic-base` and adds virtualization, development and Mystical modules. The NVIDIA gaming workstation is derived from `lyd-atomic-nvidia` and adds virtualization, development, Steam, gaming launchers and Mystical modules.

### Server

```bash
bluebuild generate recipes/lyd-server.yml -o Containerfile
bluebuild build recipes/lyd-server.yml
```

Published as `ghcr.io/lydiaperspective/lyd-atomic-server:latest`.

## GitHub Actions

The regular build workflow builds four independent component images first: shared workstation base, NVIDIA 580 base, NVIDIA open base and server. Once those are published, it builds the final workstation and NVIDIA gaming images. Pull requests validate the independent component recipes; final images are built on pushes because their custom parent images must already exist in GHCR.

**Build all images and latest ISO** builds the complete set and then creates an ISO for the selected final edition. **Build unified installer ISO** builds the Anaconda installer ISO with the edition selector. **Build installable ISO** converts one already-published final image to a single-edition ISO.

## Unified installer ISO

The installer offers:

- **KDE Workstation** — standard graphics, printing/scanning, Waterfox, SyncThingy, virtualization, development tools and Mystical theme.
- **NVIDIA Gaming Workstation** — proprietary NVIDIA 580, Steam, GameMode, MangoHud, Gamescope, Protontricks, ProtonPlus, Lutris, Heroic, virtualization, development tools and Mystical theme.
- **Server** — headless Fedora bootc server with Podman, Cockpit, SSH, firewalld and KVM/libvirt.

The selected image is downloaded from GHCR during installation; the operating-system images are not embedded in the ISO. An internet connection is required. Test the ISO in a UEFI virtual machine before physical installation and verify edition selection, storage layout, user creation, login, updates and rollback.

## Signing

For signed images, create a Cosign key pair:

```bash
cosign generate-key-pair
```

Add `cosign.key` as the Actions secret `COSIGN_PRIVATE_KEY` and `cosign.pub` as `COSIGN_PUBLIC_KEY`. Keep the private key out of the repository. Without both secrets, the workflow uses BlueBuild's `--no-sign` option.

## NVIDIA and Secure Boot

The proprietary NVIDIA image uses the 580.x driver branch. The open NVIDIA image uses the current open kernel module branch. Driver compatibility depends on the GPU generation; verify the card is supported by the selected branch. Secure Boot behavior depends on the upstream base image's signed modules and enrolled signing key. Test driver loading with `nvidia-smi` after installation.

## Mystical theme

The Mystical theme is maintained in [lyd-kde-themes](https://github.com/lydiaperspective/lyd-kde-themes). `files/scripts/install-mystical-theme.sh` pins a specific theme commit to keep builds reproducible. Update that pin only when intentionally moving to a new theme revision.

## Development tooling

The final workstation editions include Distrobox, Podman and Podman Compose. Zed remains a separate per-user application and can be installed with Zed's official Linux installer.

The BlueBuild development Distrobox is available in the development image; enter it with `lydev`. Use the recipe names above when building locally.
