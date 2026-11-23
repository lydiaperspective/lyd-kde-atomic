#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <edition> <image-tag> <output-directory>" >&2
  exit 2
fi

edition="$1"
image_tag="$2"
output_dir="$3"

command -v gh >/dev/null || { echo "GitHub CLI (gh) is required" >&2; exit 1; }
[[ -n "${GITHUB_REPOSITORY:-}" ]] || { echo "GITHUB_REPOSITORY is not set" >&2; exit 1; }

mapfile -d '' iso_files < <(find "$output_dir" -type f -name '*.iso' -print0)
if [[ ${#iso_files[@]} -ne 1 ]]; then
  echo "Expected exactly one ISO in $output_dir; found ${#iso_files[@]}" >&2
  exit 1
fi

iso="${iso_files[0]}"
iso_dir="$(dirname "$iso")"
iso_name="$(basename "$iso")"
checksum="$iso.sha256"

(
  cd "$iso_dir"
  sha256sum "$iso_name" > "$iso_name.sha256"
)

assets=()
size_bytes="$(stat -c '%s' "$iso")"
split_limit=$((1900 * 1000 * 1000))

if (( size_bytes > split_limit )); then
  echo "ISO is larger than the safe release-asset limit; splitting into 1.9 GB parts."
  split --bytes=1900M --numeric-suffixes=1 --suffix-length=3 "$iso" "$iso.part-"

  shopt -s nullglob
  parts=( "$iso".part-* )
  shopt -u nullglob
  if [[ ${#parts[@]} -lt 2 ]]; then
    echo "Expected multiple split parts, but split did not produce them." >&2
    exit 1
  fi

  for part in "${parts[@]}"; do
    assets+=( "$part" )
  done

  rm -f "$iso"

  cat > "$iso_dir/recombine-iso.sh" <<'RECOMBINE'
#!/usr/bin/env bash
set -Eeuo pipefail
DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
shopt -s nullglob
parts=( "$DIR"/*.iso.part-[0-9][0-9][0-9] )
shopt -u nullglob
if [[ ${#parts[@]} -eq 0 ]]; then
  echo "No ISO parts found beside this script." >&2
  exit 1
fi
first="${parts[0]}"
base="${first%%.part-*}"
output="${base}"
checksum="${output}.sha256"

if [[ -e "$output" ]]; then
  echo "Refusing to overwrite existing file: $output" >&2
  exit 1
fi

cat "${parts[@]}" > "$output"
(
  cd "$DIR"
  sha256sum -c "$(basename "$checksum")"
) || {
  echo "Checksum verification failed; keeping the reconstructed file and parts for inspection." >&2
  exit 1
}

echo "Reconstructed and verified: $output"
read -r -p "Delete downloaded ISO parts and SHA-256 files? [y/N] " answer
case "$answer" in
  y|Y|yes|YES)
    rm -f "${parts[@]}" "$checksum"
    echo "Parts and checksum files deleted."
    ;;
  *)
    echo "Parts and checksum files retained."
    ;;
esac
RECOMBINE
  chmod +x "$iso_dir/recombine-iso.sh"
  assets+=( "$checksum" "$iso_dir/recombine-iso.sh" )
else
  assets+=( "$iso" "$checksum" )
fi

safe_image_tag="$(printf '%s' "$image_tag" | tr -c 'A-Za-z0-9._-' '-')"
release_prefix="iso-${edition}-${safe_image_tag}"
release_tag="$release_prefix"
release_title="Lyd Atomic ${edition} ISO (${image_tag})"
release_notes="Installable Lyd Atomic ISO for the **${edition}** edition, built from image tag **${image_tag}**.

SHA-256 checksum is included. If the ISO was split into multiple assets, download all part files and recombine-iso.sh into the same directory, then run the script."

# Keep one rolling release for each edition and image tag. Remove the prior
# stable release and any older run-ID releases before publishing the replacement.
echo "Looking for previous latest releases matching $release_prefix..."
mapfile -t previous_releases < <(
  gh release list --repo "$GITHUB_REPOSITORY" --limit 100 --json tagName --jq '.[].tagName' |
    while IFS= read -r existing_tag; do
      case "$existing_tag" in
        "$release_prefix"*) printf '%s\n' "$existing_tag" ;;
      esac
    done
)

for previous_tag in "${previous_releases[@]}"; do
  echo "Deleting previous ISO release: $previous_tag"
  gh release delete "$previous_tag" --repo "$GITHUB_REPOSITORY" --yes --cleanup-tag
done

echo "Publishing replacement release $release_tag with ${#assets[@]} assets."
gh release create "$release_tag" "${assets[@]}" \
  --repo "$GITHUB_REPOSITORY" \
  --title "$release_title" \
  --notes "$release_notes" \
  --target "${GITHUB_SHA:-main}"

echo "Published: https://github.com/$GITHUB_REPOSITORY/releases/tag/$release_tag"
