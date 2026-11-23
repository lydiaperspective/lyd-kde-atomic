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

## Server edition

Build the headless server image with:

```bash
bluebuild generate recipes/lyd-server.yml -o Containerfile
bluebuild build recipes/lyd-server.yml
```

Published image: `ghcr.io/lydiaperspective/lyd-atomic-server:latest`.

The server recipe uses Fedora's Fedora 45 bootc base, installs Podman and Podman Compose, Cockpit with the Podman, Machines, Storage, NetworkManager, SELinux and SOS report modules, plus KVM/libvirt virtualization support. It enables `cockpit.socket`, `firewalld`, `sshd` and `libvirtd` at boot.

The default public firewalld zone permits SSH (TCP 22), Cockpit (TCP 9090) and DHCPv6 client traffic. Container-published ports are intentionally not opened automatically because the required ports depend on each workload. Add explicit permanent rules only for services you intend to expose. Do not expose libvirt management, VNC or SPICE ports directly to untrusted networks.

## GitHub Actions

Pushes to `main` and manual dispatch build the NVIDIA, Standard and Server editions in parallel. Pull requests validate all three recipes without publishing. The build workflow publishes each image under its recipe name.

## GitHub Actions signing

The build workflow can publish unsigned bootstrap images so the first build works without extra setup. For signed images, create a Cosign key pair once on a trusted workstation:

```bash
cosign generate-key-pair
```

Add the contents of `cosign.key` as the repository Actions secret `COSIGN_PRIVATE_KEY` and the contents of `cosign.pub` as `COSIGN_PUBLIC_KEY`. Keep the private key out of the repository. When both secrets are present, the workflow signs the image; otherwise it uses BlueBuild's `--no-sign` option. GitHub Actions uses its token to publish images to GHCR.

## ISO generation

Run the **Build installable ISO** workflow manually after the relevant image has been published. Choose the NVIDIA, Standard or Server edition and the image tag. The workflow downloads that image, creates an ISO and attaches a SHA256 checksum. Artifacts are retained for 14 days.

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

On all editions, `lydsetup` can prepare a BlueBuild development environment using Distrobox. If Distrobox is missing, it layers the package into the next host deployment; reboot, run `lydsetup` again, and select the development option. The setup creates `lyd-atomic-dev` from BlueBuild's official `ghcr.io/blue-build/cli:latest-distrobox` image, exports the `bluebuild` binary, and routes Podman commands back to the host engine. Enter it with `distrobox enter lyd-atomic-dev`, clone this repository in the shared home directory, and build one of the recipes with `bluebuild build recipes/<recipe>.yml`. The container is rootless and intended for building/testing, not locally rebasing the host; use CI for publishing.


`lydsetup` can install Tailscale from the official Fedora repository on all editions. It layers the package in a new deployment, enables `tailscaled` after reboot, and optionally runs `tailscale up` to authenticate the machine. No inbound Tailscale port is opened in firewalld by default.

On workstation editions, `lydsetup` can also run Zed's official Linux installer. Zed is installed per-user under `~/.local`, so this does not create an rpm-ostree deployment. See [Zed's Linux installation documentation](https://zed.dev/docs/installation).


`lydsetup` uses system package layering for optional RPMs. A package change creates a new deployment and normally requires a reboot before the package is available. Some setup tasks therefore require a second run after reboot to enable services or complete configuration. The utility does not reboot automatically.
