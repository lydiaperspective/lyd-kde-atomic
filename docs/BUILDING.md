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

## GitHub Actions secrets

Create a Cosign key pair once on a trusted workstation:

```bash
cosign generate-key-pair
```

Add the contents of `cosign.key` as the repository Actions secret `COSIGN_PRIVATE_KEY` and the contents of `cosign.pub` as `COSIGN_PUBLIC_KEY`. Keep the private key out of the repository and do not upload it as an artifact. GitHub Actions uses its token to publish the image to GHCR.

## Publish and ISO build

Pushes to `main` and manual dispatch publish the image to GHCR. Pull requests validate the recipe without publishing. Run the separate **Build installable ISO** workflow manually after a successful image build; it converts the selected GHCR tag into an ISO and attaches a SHA256 checksum. The workflow artifact is retained for 14 days.

## Image installation

The ISO is intended for fresh installations. Test it in a UEFI VM first, including networking, user creation, KDE login, Flatpak setup, update deployment, rollback, and shutdown/reboot. Review the installer's storage choices carefully before confirming any disk changes.

## NVIDIA driver

The initial image uses RPM Fusion's proprietary `akmod-nvidia-580xx` branch and matching 580xx userspace packages. This is the legacy branch for supported Maxwell, Pascal and Volta GPUs; it is not the current driver branch for newer GPUs. The image build explicitly checks for the 580xx packages and runs `akmods --force`, so a missing or unbuildable kernel module should fail the build rather than silently falling back. Verify the installed driver with `nvidia-smi` after boot. Secure Boot may require enrolling/signing the akmods key before the module can load.

## Optional feature manager

`lydsetup` uses system package layering for optional RPMs. A package change creates a new deployment and requires a reboot before the new package is available. Some setup tasks therefore require a second run after reboot to enable services or complete configuration. The utility does not reboot automatically.
