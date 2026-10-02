#!/usr/bin/env bash
# Anonymous per-file fetch of AADC EDS datasets.
# Record:  https://data.aad.gov.au/eds/api/dataset/<eds_id>   (gives uuid)
# Files:   https://data.aad.gov.au/eds/api/dataset/<uuid>/objects?recursive=true&removeBasePath=true
# Get:     https://data.aad.gov.au/eds/api/dataset/<uuid>/object/download?prefix=<file>
#          -> 302 to a presigned URL on transfer.data.aad.gov.au (no login).
# AADC publishes no checksums; we verify size against the listing and record sha256.
#
# Usage: fetch_aadc_eds.sh DEST_DIR EDS_ID [EDS_ID ...]
# Output: DEST_DIR/<eds_id>_<metadata_entry_id>/<files>, record.json, objects.json;
#         DEST_DIR/manifest.tsv (appended)
# Needs: bash, curl, jq, sha256sum
set -euo pipefail
dest="$1"; shift
mkdir -p "$dest"
api='https://data.aad.gov.au/eds/api/dataset'
manifest="$dest/manifest.tsv"
[[ -f "$manifest" ]] || printf 'eds_id\tuuid\tmetadata_entry_id\tfilename\tsize_bytes\tsha256\turl\tfetched_utc\tlast_modified\n' > "$manifest"
c=(--fail --silent --show-error --retry 5 --retry-delay 5 --retry-all-errors)
for id in "$@"; do
  rec=$(curl "${c[@]}" "$api/$id")
  uuid=$(jq -r .uuid <<<"$rec"); entry=$(jq -r .metadata_entry_id <<<"$rec")
  d="$dest/${id}_${entry}"; mkdir -p "$d"
  printf '%s\n' "$rec" > "$d/record.json"
  curl "${c[@]}" -o "$d/objects.json" "$api/$uuid/objects?recursive=true&removeBasePath=true"
  jq -r '.[] | [.name, .size, .lastModified] | @tsv' "$d/objects.json" |
  while IFS=$'\t' read -r name size lastmod; do
    out="$d/$name"; mkdir -p "$(dirname "$out")"
    url="$api/$uuid/object/download?prefix=$(jq -rn --arg s "$name" '$s|@uri')"
    have=$( [[ -f "$out" ]] && stat -c %s "$out" || echo -1 )
    if [[ "$have" != "$size" ]]; then
      echo "fetching $id/$name ($size bytes)" >&2
      curl "${c[@]}" --location -o "$out" "$url"
    fi
    got=$(stat -c %s "$out")
    if [[ "$got" != "$size" ]]; then echo "SIZE MISMATCH $id/$name: listing $size, got $got" >&2; exit 1; fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$uuid" "$entry" "$name" "$got" \
      "$(sha256sum "$out" | cut -d' ' -f1)" "$url" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$lastmod" >> "$manifest"
  done
done
