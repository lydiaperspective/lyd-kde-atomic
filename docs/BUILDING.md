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

## Publish and ISO build

Pushes to `main` and manual dispatch publish the image to GHCR. The ISO workflow runs separately and consumes the published image. The ISO workflow requires GitHub Actions to have package read access and sufficient runner storage.

## Image installation

The ISO is intended for fresh installations. Test it in a UEFI VM first, including networking, user creation, KDE login, Flatpak setup, update deployment, rollback, and shutdown/reboot. Do not assume an image-based installer will preserve existing disk contents. Review the installer storage screen carefully before confirming any disk changes.

## NVIDIA driver note

The project currently targets the proprietary NVIDIA 580-series driver for older supported GPUs. The exact driver build must match the Fedora kernel shipped by the image. A driver build that is not available for the selected Fedora release/kernel must fail the image build rather than silently falling back to a different major driver series. Validate the driver version with `nvidia-smi` after installation.

## Optional feature manager

`lydsetup` uses system package layering for optional RPMs. The system may need a reboot after each feature is staged. It does not silently apply a reboot. Review the transaction and reboot when convenient.
