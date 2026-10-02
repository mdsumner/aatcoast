#!/usr/bin/env bash
# Anonymous fetch of AADC GeoServer WFS layers as GeoJSON (EPSG:4326).
# The EDS file downloads (data.aad.gov.au/eds/<id>/download) need an email
# address (one-time link or S3 keys), so this uses the public WFS instead.
#
# Usage: fetch_aadc_wfs.sh DEST_DIR LAYER [LAYER ...]
#   e.g. fetch_aadc_wfs.sh wfs Mapping:coastline_py Mapping:himi_coastline_py
# Output: DEST_DIR/<layer>.geojson, DEST_DIR/manifest.tsv (appended)
# Needs: bash, curl, jq, sha256sum
set -euo pipefail
dest="$1"; shift
mkdir -p "$dest"
base='https://data.aad.gov.au/geoserver/ows?service=WFS&version=2.0.0&request=GetFeature'
manifest="$dest/manifest.tsv"
[[ -f "$manifest" ]] || printf 'layer\tfilename\tn_features\tsize_bytes\tsha256\turl\tfetched_utc\n' > "$manifest"
for layer in "$@"; do
  url="${base}&typeNames=${layer}&outputFormat=application/json&srsName=EPSG:4326"
  out="$dest/${layer#*:}.geojson"
  hits=$(curl -sS --fail "${base}&typeNames=${layer}&resultType=hits" | grep -oE 'numberMatched="[0-9]+"' | grep -oE '[0-9]+')
  curl --fail --silent --show-error --retry 5 --retry-delay 5 --retry-all-errors -o "$out" "$url"
  n=$(jq '.features | length' "$out")
  if [[ "$n" != "$hits" ]]; then echo "COUNT MISMATCH $layer: server says $hits, got $n" >&2; exit 1; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$layer" "$(basename "$out")" "$n" "$(stat -c %s "$out")" \
    "$(sha256sum "$out" | cut -d' ' -f1)" "$url" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$manifest"
done
