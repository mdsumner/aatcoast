# ADD (SCAR Antarctic Digital Database) raw acquisition

Status 2026-09-30: DOWNLOADED. raw/ holds the high-res and medium-res
coastline polygons and lines (ADD 7.12 GeoPackages, 273 MB), each with its
record.json; sizes match the records and sha256 is in raw/manifest.tsv.
Fields confirmed in attributes.md. To reproduce or refresh:

    ./fetch_add.sh -f 'GeoPackage' raw 13c4d2f1-8903-4d7f-8977-592121975554 dbaf29f5-c8dc-4e79-aeb1-1df316e951ec

(high-res coastline polygons + high-res coastline lines, ADD 7.12, ~260 MB).
Add c9c6d671-ad19-4a78-96b2-7d47e9bac46a / 37ad06ff-888d-452c-be85-018e59600103
for the medium-res polygons / lines.

## How the BAS catalogue resolves to files

1. Item page (human): https://data.bas.ac.uk/items/<uuid>/  -- not a download.
2. Record (machine): https://data.bas.ac.uk/records/<uuid>.json (also .xml
   ISO 19115-3, .html). Same uuid is the DOI suffix: 10.5285/<uuid>.
3. In the record, distribution[] entries with
   transfer_option.online_resource.function == "download" give:
   - href: a RAMADDA URL
     https://ramadda.data.bas.ac.uk/repository/entry/get/<name>?entryid=synth%3A<uuid>%3A<base64("/<filename>")>
   - size.magnitude: exact byte count (stored as a float).
   These are plain HTTPS GETs; no auth, no cookies, no JS.
4. No checksums are published. We verify byte count against the record and
   record our own sha256 in manifest.tsv.
5. Filename: take it from the base64 part of entryid, not the URL path. v7.2/v7.3
   items have paths like add_streams_v7.3.application/geopackage+sqlite3.
6. Collection membership: the SCAR ADD collection record
   e74543c0-4c4e-4b41-aa33-5bb2f67df389 lists members as aggregations with
   association_type "isComposedOf". Each item links its predecessor by
   "revisionOf", so version history can be walked from the records.
7. ArcGIS Living Atlas FeatureServer/VectorTileServer endpoints are also
   listed. They are useful for quick checks (field schema, counts, distinct
   values via /query) but are not the archival source.

## Best practice (general, for any raw source in this project)

- Resolve from the machine-readable metadata record, never scrape the page.
- Store the record next to the file (record.json) so the provenance of each
  version is frozen alongside the bytes.
- Layout: raw/<uuid>/<original filename>; never rename or edit raw files.
  Reformatting happens downstream, from raw, by script.
- Verify published size; compute sha256; write a manifest row with URL,
  fetch time and Last-Modified.
- Re-runs are idempotent: files whose size already matches are skipped,
  partial downloads resume.
- Prefer GeoPackage over shapefile (no 10-char field-name truncation, one file).
- Pin by uuid + edition. A new ADD edition gets a new uuid, so a new
  edition lands side by side rather than overwriting.

## Files here

- fetch_add.sh -- the fetcher (bash, curl, jq, sha256sum, base64).
- add_catalogue_2026-09-30.tsv -- every downloadable file in the current ADD
  collection (23 files, uuid, edition, bytes, URL). Resolved via a web
  fetch that summarises pages; every entryid was decoded and checked against
  its filename and uuid. The fetcher re-reads the live records, so the
  script does not depend on this table.
- attributes.md -- layer and field inventory for the coastline layers.

## Scope note

ADD covers south of 60S only (record bbox -90..-60). Heard/McDonald (~53S) and
Macquarie (~54.5S) are not in ADD; they come from the AADC survey thread.
