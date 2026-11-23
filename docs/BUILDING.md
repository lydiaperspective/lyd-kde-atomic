# Building Lyd KDE Atomic

## Local image builds

Install Podman and the BlueBuild CLI on a supported Linux host.

### NVIDIA edition

```bash
bluebuild generate recipes/lyd-kde.yml -o Containerfile
bluebuild build recipes/lyd-kde.yml
```

Published image: `ghcr.io/lydiaperspective/lyd-kde-atomic:latest`.

### Intel / generic edition

```bash
bluebuild generate recipes/lyd-kde-intel.yml -o Containerfile
bluebuild build recipes/lyd-kde-intel.yml
```

Published image: `ghcr.io/lydiaperspective/lyd-kde-atomic-intel:latest`.

The Intel recipe uses the standard Fedora Kinoite base and does not install proprietary NVIDIA drivers. It is intended for Intel iGPU systems and other non-NVIDIA hardware.

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

Run the **Build installable ISO** workflow manually after the relevant image has been published. Choose the NVIDIA or Intel edition and the image tag. The workflow downloads that image, creates an ISO and attaches a SHA256 checksum. Artifacts are retained for 14 days.

## Image installation

Test each edition in a UEFI VM before physical installation, including networking, user creation, KDE login, Flatpak setup, update deployment, rollback, shutdown and reboot. Review storage choices carefully before confirming any disk changes.

## NVIDIA driver and Secure Boot

The NVIDIA edition is based on BlueBuild's Fedora 45 Kinoite NVIDIA image, which provides the proprietary NVIDIA 580.x driver and a prebuilt, signed kernel module. The NVIDIA recipe verifies that the installed kernel module reports version 580.x. This branch is intended for supported older NVIDIA GPUs; newer GPUs should use a current driver branch instead.

For Secure Boot, enroll the BlueBuild akmods certificate before relying on the NVIDIA module:

```bash
sudo mokutil --import /etc/pki/akmods/certs/akmods-blue-build.der
```

Reboot, enroll the key in the firmware's MOK manager, then verify the driver with `nvidia-smi`. If Secure Boot is disabled, enrollment is not required.

## Optional feature manager

`lydsetup` uses system package layering for optional RPMs. A package change creates a new deployment and normally requires a reboot before the package is available. Some setup tasks therefore require a second run after reboot to enable services or complete configuration. The utility does not reboot automatically.
