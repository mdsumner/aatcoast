#!/usr/bin/env bash
# Reproducible bulk fetch of SCAR Antarctic Digital Database (ADD) items from
# the BAS data catalogue (UK Polar Data Centre).
#
# The item web page (data.bas.ac.uk/items/<uuid>/) is not a download URL.
# Each item has a machine-readable ISO 19115 record at
#   https://data.bas.ac.uk/records/<uuid>.json
# whose distribution[].transfer_option carries the real download href (a
# RAMADDA "synth" URL) and the exact size in bytes. BAS publishes no checksums,
# so we verify size and record our own sha256.
#
# Usage:  fetch_add.sh [-f FORMAT_REGEX] DEST_DIR UUID [UUID ...]
#   FORMAT_REGEX matches distribution format names, default 'GeoPackage'
#   (use 'GeoPackage|Shapefile' for both).
# Output: DEST_DIR/<uuid>/<filename>, DEST_DIR/<uuid>/record.json,
#         DEST_DIR/manifest.tsv (appended, one row per file)
# Needs: bash, curl, jq, sha256sum
set -euo pipefail

fmt='GeoPackage'
if [[ "${1:-}" == "-f" ]]; then fmt="$2"; shift 2; fi
dest="$1"; shift
mkdir -p "$dest"
manifest="$dest/manifest.tsv"
[[ -f "$manifest" ]] || printf 'uuid\ttitle\tedition\tformat\tfilename\tsize_bytes\tsha256\turl\tfetched_utc\tlast_modified\n' > "$manifest"

curl_opts=(--fail --location --silent --show-error --retry 5 --retry-delay 5 --retry-all-errors)

for uuid in "$@"; do
  d="$dest/$uuid"; mkdir -p "$d"
  curl "${curl_opts[@]}" -o "$d/record.json" "https://data.bas.ac.uk/records/${uuid}.json"
  title=$(jq -r '.identification.title.value // .identification.title // ""' "$d/record.json")
  edition=$(jq -r '.identification.edition // ""' "$d/record.json")
  jq -r --arg re "$fmt" '
    .distribution[]
    | select(.format.format | test($re))
    | select(.transfer_option.online_resource.function == "download")
    | [.format.format, (.transfer_option.size.magnitude // 0 | floor), .transfer_option.online_resource.href]
    | @tsv' "$d/record.json" |
  while IFS=$'\t' read -r format size url; do
    # The real filename is base64-encoded in the RAMADDA entryid
    # (synth:<uuid>:<base64 path>). Older (v7.2/v7.3) URLs have a path like
    # add_streams_v7.3.application/geopackage+sqlite3, so never trust the URL path.
    b64=$(printf '%s' "${url##*entryid=}" | sed 's/%3A/:/g; s/%3D/=/g' | cut -d: -f3)
    fname=$(basename "$(printf '%s' "$b64" | base64 -d)")
    out="$d/$fname"
    have=$( [[ -f "$out" ]] && stat -c %s "$out" || echo -1 )
    if [[ "$have" != "$size" ]]; then
      echo "fetching $fname ($size bytes)" >&2
      hdr=$(mktemp)
      curl "${curl_opts[@]}" --continue-at - -D "$hdr" -o "$out" "$url"
      lastmod=$(grep -i '^last-modified:' "$hdr" | tail -1 | cut -d' ' -f2- | tr -d '\r' || true)
      rm -f "$hdr"
    else
      echo "have $fname" >&2; lastmod=""
    fi
    got=$(stat -c %s "$out")
    if [[ "$size" != "0" && "$got" != "$size" ]]; then
      echo "SIZE MISMATCH $fname: record says $size, got $got" >&2; exit 1
    fi
    sha=$(sha256sum "$out" | cut -d' ' -f1)
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$uuid" "$title" "$edition" "$format" \
      "$fname" "$got" "$sha" "$url" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$lastmod" >> "$manifest"
  done
done
