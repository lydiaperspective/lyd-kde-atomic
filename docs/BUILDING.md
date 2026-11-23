# Building Lyd Atomic

## Local image builds

Install Podman and the BlueBuild CLI on a supported Linux host.

### NVIDIA edition

```bash
bluebuild generate recipes/lyd-kde.yml -o Containerfile
bluebuild build recipes/lyd-kde.yml
```

Published image: `ghcr.io/lydiaperspective/lyd-atomic-nvidia:latest`.

### Standard edition

```bash
bluebuild generate recipes/lyd-kde-intel.yml -o Containerfile
bluebuild build recipes/lyd-kde-intel.yml
```

Published image: `ghcr.io/lydiaperspective/lyd-atomic-standard:latest`.

The Standard recipe uses the standard Fedora Kinoite base and does not install proprietary NVIDIA drivers by default. It is intended for Intel/AMD systems, but an NVIDIA driver can be layered after installation using `lydsetup`.

The output is a local OCI image. Use `bluebuild switch` only on a test machine or VM; it builds and stages a new deployment for the next boot.

## GitHub Actions

Pushes to `main` and manual dispatch build both hardware editions in parallel. Pull requests validate both recipes without publishing. The build workflow publishes each image under its recipe name.

## GitHub Actions signing

The build workflow can publish unsigned bootstrap images so the first build works without extra setup. For signed images, create a Cosign key pair once on a trusted workstation:

```bash
cosign generate-key-pair
```

Add the contents of `cosign.key` as the repository Actions secret `COSIGN_PRIVATE_KEY` and the contents of `cosign.pub` as `COSIGN_PUBLIC_KEY`. Keep the private key out of the repository. When both secrets are present, the workflow signs the image; otherwise it uses BlueBuild's `--no-sign` option. GitHub Actions uses its token to publish images to GHCR.

## ISO generation

Run the **Build installable ISO** workflow manually after the relevant image has been published. Choose the NVIDIA or Standard edition and the image tag. The workflow downloads that image, creates an ISO and attaches a SHA256 checksum. Artifacts are retained for 14 days.

## Image installation

Test each edition in a UEFI VM before physical installation, including networking, user creation, KDE login, Flatpak setup, update deployment, rollback, shutdown and reboot. Review storage choices carefully before confirming any disk changes.

## NVIDIA driver and Secure Boot

The NVIDIA edition is based on BlueBuild's Fedora 45 Kinoite NVIDIA image, which provides the proprietary NVIDIA 580.x driver and a prebuilt, signed kernel module. The NVIDIA recipe verifies that the installed kernel module reports version 580.x. This branch is intended for supported older NVIDIA GPUs; newer GPUs should use a current driver branch instead.

The Standard edition can add the current RPM Fusion NVIDIA driver using `lydsetup`. The setup is deliberately staged:

1. Add the RPM Fusion repository release packages to a new deployment.
2. Reboot and run `lydsetup` again.
3. Layer `akmod-nvidia`, `xorg-x11-drv-nvidia` and `xorg-x11-drv-nvidia-cuda`.
4. Reboot into the new deployment and allow the akmods service time to compile the kernel module.
5. Verify with `nvidia-smi` and `modinfo -F version nvidia`.

This uses the current RPM Fusion driver branch, which may differ from the NVIDIA edition's pinned 580.x driver. If Secure Boot is enabled, the generated module may be blocked unless module signing is configured and its certificate is enrolled. `lydsetup` detects Secure Boot and warns, but does not generate or enroll signing keys. Keep a working deployment available before enabling the driver.

## AppImage, Flatpak and Aurorae support

Both image recipes install `fuse` and `fuse-libs` for FUSE 2 compatibility, plus `fuse3` and `fuse3-libs` for FUSE 3. This provides the host FUSE components required by many current and legacy AppImages. Some AppImages still require additional libraries or a compatible runtime; FUSE support cannot guarantee every third-party AppImage will run.

Flatpak is installed as a system package. BlueBuild's `default-flatpaks` module configures Flathub as a system remote and installs Waterfox. `plasma-discover-flatpak` supplies Discover's Flatpak integration, while `xdg-desktop-portal` and `xdg-desktop-portal-kde` provide desktop portal services used by sandboxed applications.

The Fedora `aurorae` package installs the KWin Aurorae decoration engine. It enables compatible SVG-based Aurorae window decorations to be installed and selected in KDE System Settings; it is not itself a theme pack.

## Mystical theme dependency

The Mystical KDE theme and its supporting assets are maintained in [lyd-kde-themes](https://github.com/lydiaperspective/lyd-kde-themes). The image build script `files/scripts/install-mystical-theme.sh` clones that repository and checks out a specific commit before installing the assets. Update the pinned commit in that script when intentionally moving the images to a newer theme revision. Do not change it to a floating branch name: commit pinning makes image builds reproducible.

## Optional feature manager

`lydsetup` uses system package layering for optional RPMs. A package change creates a new deployment and normally requires a reboot before the package is available. Some setup tasks therefore require a second run after reboot to enable services or complete configuration. The utility does not reboot automatically.
