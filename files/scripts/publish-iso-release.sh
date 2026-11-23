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
[[ -n "${GITHUB_RUN_ID:-}" ]] || { echo "GITHUB_RUN_ID is not set" >&2; exit 1; }

mapfile -d '' iso_files < <(find "$output_dir" -type f -name '*.iso' -print0)
if [[ ${#iso_files[@]} -ne 1 ]]; then
  echo "Expected exactly one ISO in $output_dir; found ${#iso_files[@]}" >&2
  exit 1
fi

iso="${iso_files[0]}"
iso_dir="$(dirname "$iso")"
iso_name="$(basename "$iso")"
checksum="$iso.sha256"

# Keep the checksum portable: it references only the ISO filename.
(
  cd "$iso_dir"
  sha256sum "$iso_name" > "$iso_name.sha256"
)

assets=()
size_bytes="$(stat -c '%s' "$iso")"
# GitHub Release assets have a 2 GiB per-file limit. Split conservatively below it.
split_limit=$((1900 * 1000 * 1000))

if (( size_bytes > split_limit )); then
  echo "ISO is larger than the safe release-asset limit; splitting into 1.9 GB parts."
  split --bytes=1900M --numeric-suffixes=1 --suffix-length=3 \
    "$iso" "$iso.part-"

  shopt -s nullglob
  parts=( "$iso".part-* )
  shopt -u nullglob
  if [[ ${#parts[@]} -lt 2 ]]; then
    echo "Expected multiple split parts, but split did not produce them." >&2
    exit 1
  fi

  for part in "${parts[@]}"; do
    part_name="$(basename "$part")"
    ( cd "$iso_dir" && sha256sum "$part_name" > "$part_name.sha256" )
    assets+=( "$part" "$part.sha256" )
  done

  # The full ISO is reconstructable from the parts and is not uploaded twice.
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
    rm -f "${parts[@]}" "${parts[@]/%/.sha256}" "$checksum"
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
release_tag="iso-${edition}-${safe_image_tag}-${GITHUB_RUN_ID}"
release_title="Lyd Atomic ${edition} ISO (${image_tag})"
release_notes="Installable Lyd Atomic ISO for the **${edition}** edition, built from image tag **${image_tag}**.

SHA-256 checksum is included. If the ISO was split into multiple assets, download all part files and `recombine-iso.sh` into the same directory, then run the script."

echo "Publishing release $release_tag with ${#assets[@]} assets."
gh release create "$release_tag" "${assets[@]}" \
  --repo "$GITHUB_REPOSITORY" \
  --title "$release_title" \
  --notes "$release_notes" \
  --target "${GITHUB_SHA:-main}"

echo "Published: https://github.com/$GITHUB_REPOSITORY/releases/tag/$release_tag"
