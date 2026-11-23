# Building Lyd KDE Atomic

## Local image build

Install Podman and the BlueBuild CLI on a supported Linux host.

```bash
git clone https://github.com/lydiaperspective/lyd-kde-atomic.git
cd lyd-kde-atomic
bluebuild generate recipes/lyd-kde.yml -o Containerfile
bluebuild build recipes/lyd-kde.yml
```

The build uses the recipe in `recipes/lyd-kde.yml`. The output is a local OCI image. Use `bluebuild switch recipes/lyd-kde.yml` only on a test machine or VM; it builds and stages a new deployment for the next boot.

## GitHub Actions signing

The build workflow can publish unsigned bootstrap images so the first build works without extra setup. For signed images, create a Cosign key pair once on a trusted workstation:

```bash
cosign generate-key-pair
```

Add the contents of `cosign.key` as the repository Actions secret `COSIGN_PRIVATE_KEY` and the contents of `cosign.pub` as `COSIGN_PUBLIC_KEY`. Keep the private key out of the repository and do not upload it as an artifact. When both secrets are present, the workflow signs the image; otherwise it uses BlueBuild's `--no-sign` option. GitHub Actions uses its token to publish the image to GHCR.

## Publish and ISO build

Pushes to `main` and manual dispatch publish the image to GHCR. Pull requests validate the recipe without publishing. Run the separate **Build installable ISO** workflow manually after a successful image build; it converts the selected GHCR tag into an ISO and attaches a SHA256 checksum. The workflow artifact is retained for 14 days.

## Image installation

The ISO is intended for fresh installations. Test it in a UEFI VM first, including networking, user creation, KDE login, Flatpak setup, update deployment, rollback, and shutdown/reboot. Review the installer's storage choices carefully before confirming any disk changes.

## NVIDIA driver and Secure Boot

The image is based on BlueBuild's Fedora 45 Kinoite NVIDIA image, which provides the proprietary NVIDIA 580.x driver and a prebuilt, signed kernel module. The recipe verifies that the installed kernel module reports version 580.x. This branch is intended for supported older NVIDIA GPUs; newer GPUs should use a current driver branch instead.

For Secure Boot, enroll the BlueBuild akmods certificate before relying on the NVIDIA module:

```bash
sudo mokutil --import /etc/pki/akmods/certs/akmods-blue-build.der
```

Reboot, enroll the key in the firmware's MOK manager, then verify the driver with `nvidia-smi`. If Secure Boot is disabled, the enrollment step is not required.

## Optional feature manager

`lydsetup` uses system package layering for optional RPMs. A package change creates a new deployment and requires a reboot before the new package is available. Some setup tasks therefore require a second run after reboot to enable services or complete configuration. The utility does not reboot automatically.
