# AADC downloads (2026-09-30)

Written by the "ADD and AADC downloads" thread. The survey thread's own files
in ../ are untouched.

## Result in one paragraph

UPDATE (later on 2026-09-30, after transfer.data.aad.gov.au was allowlisted):
all shortlisted EDS datasets plus McDonald_Island_Coastline_2020 (eds 6013)
and Heard_Island_topographic_data_2017_2019 (eds 6018) are downloaded to
eds/ with fetch_aadc_eds.sh, sizes verified against the public listings and
sha256 in eds/manifest.tsv (104 files, 108 MB). Fields: eds_fields.md.

The legacy link eds/<id>/download is a web app with an email form. The
per-file route /eds/api/dataset/<uuid>/object/download?prefix=<file> is
anonymous (302 to a presigned transfer.data.aad.gov.au URL). The AADC WFS
also serves consolidated coastline layers anonymously (wfs/).

## Files

- fetch_aadc_eds.sh -- per-file EDS fetch: record -> file listing -> each
  file via object/download; checks size, appends manifest rows.
- eds/<eds_id>_<entry_id>/ -- every file of each dataset + record.json +
  objects.json; eds/manifest.tsv.
- eds_fields.md -- geometry type, count, bbox, CRS and field values per layer.

- fetch_aadc_wfs.sh -- anonymous WFS fetch to GeoJSON (EPSG:4326), checks the
  feature count against the server's numberMatched, appends manifest rows.
- wfs/*.geojson + wfs/manifest.tsv -- the four layers, sha256 recorded.
  WFS output is not byte-stable: two fetches differ only in the trailing
  "timeStamp" member, so sha256 identifies a fetch, not a data version.
- eds_listings/ds_<id>.json -- EDS dataset record (uuid, path, byte count).
- eds_listings/obj_<id>.json -- public file listing for each dataset.
- wfs_layers_2026-09-30.tsv -- all 55 WFS layers (GetCapabilities). No
  separate Macquarie layer: Macquarie is inside Mapping:coastline_py. HIMI
  also has relief, hydrology, ice_feature, landform, vegetation and a
  HIMI_Seamask layer.

Endpoints (no auth):
- https://data.aad.gov.au/eds/api/dataset/<eds_id>                -> record
- https://data.aad.gov.au/eds/api/dataset/<uuid>/objects?recursive=true&removeBasePath=true -> file list
- https://data.aad.gov.au/eds/api/dataset/<uuid>/object?prefix=<f> -> 401
- https://data.aad.gov.au/eds/api/dataset/<uuid>/object/download?prefix=<file>
  -> 302 to an anonymous presigned URL on transfer.data.aad.gov.au (valid
  24 h). This is the per-file route (found by Michael for
  McDonald_Island_Coastline_2020.gpkg, eds 6013, uuid
  7caa91f8-46d4-4d0c-83b7-f46a1760f510) and it works for the older
  shortlist datasets too (tested 3865). Works with GDAL /vsicurl/. From this
  cloud environment the redirect target is blocked, so the allowlist needs
  transfer.data.aad.gov.au before these files can be fetched here.
- POST .../eds/api/dataset/<uuid>/download {email_address} -> whole-dataset
  zip link or S3 keys by email (the web app's route)
- https://data.aad.gov.au/geoserver/ows?service=WFS&... -> 55 layers

## WFS layers downloaded

| layer | features | MB | content |
|---|---|---|---|
| Mapping:coastline_py | 10,209 | 162 | AAT + Macquarie polygons, 22 source datasets |
| Mapping:coastline_ln | 21,326 | 168 | AAT + Macquarie lines, 26 source datasets |
| Mapping:himi_coastline_py | 3,399 | 83 | Heard + McDonald polygons |
| Mapping:himi_coastline_ln | 3,453 | 82 | Heard + McDonald lines |

Fields (all four share a provenance block per feature):
feat_type, source, date_capture, date_flag, metadata_id, feature_source,
spatial_method, spat_reliability_date, att_reliability_date, attribute_source,
planimetric_accuracy, elevation_accuracy, plus st_area/st_perimeter (py) or
st_length (ln). coastline_py adds group_name, jurisdiction. The _ln layers add
type, surface, certainty.

metadata_id links each feature to an AADC metadata record, so provenance is
per feature (unlike ADD polygons).

### Heard and McDonald (himi_*)

- Heard_Island_topographic_data_2017_2019 (3,324 py): WorldView-3 mosaic
  2017-2019, digitised at 1:1000 by AAD, or GA image segmentation.
- McDonald_Island_Coastline_2020 (75 py): GA segmentation, 2020.
- date_capture 2017-02-03 .. 2020-06-25.
- McDonald 2020 in the WFS: 86 lines / 75 polygons with 15-ish fields. The
  source GeoPackage (eds 6013, layer Coastline_ln) has 106 lines and extra
  fields (status, display), so the WFS is a derived/merged view, not the
  file itself. Prefer the gpkg once transfer.data.aad.gov.au is reachable.
- feat_type: Island 10, Offshore rock 3,389.
- This is newer than every shortlist pick (Heard 2009, McDonald 2003) and
  covers the post-eruption McDonald coast, which the survey said had no
  vector coastline after 2003. These records were not in the CMR mirror.

### Macquarie (in coastline_py)

- group_name: Macquarie Island, Judge and Clerk Islets (20),
  Bishop and Clerk Islets (38), so the outlying islets ARE present.
- Sources: macca_coast_ambis_gis (the 1:50k shortlist pick) and Macca_DSAM
  (150 island + 272 offshore rock polygons; not on the shortlist).
- date_capture is empty for all Macquarie features.
- Caution: the islets appear twice, once as "Continent and Island" and once
  as "Island" (e.g. 19 + 19 Bishop and Clerk). Probably overlapping
  duplicates from two classifications; check before merging.

### AAT (coastline_py)

Main sources by feature count: east_antarctic_25k_topographic_data_2023
(2,215), vest_hills_gis (826), Mawson_coastline_approach (796), gis135 (591),
Raur50k, Wind50k, bolingen_islands_digitising_2024,
larsemann_hills_1K_topo_2026. date_capture 2017..2024 where filled (2,554
missing). This is AADC's own AAT compilation, separate from ADD.

## EDS shortlist: what each dataset contains

(Not downloaded: email gate. Sizes from the public listing.)

| eds | entry id | files |
|---|---|---|
| 3865 | Heard_Island_digitising_2009 | coastline_ln_gg.shp (line, "gg" = geographic), 899 KB total |
| 2558 | Heard_Island_digitising_2009 | offshore rocks: ONLY xml/LICENSE/README, no shapefile |
| 4093 | Heard_Island_digitising_2009 | Heard_Island_py.shp (polygon), 678 KB |
| 1368 | heard_50kmap_gis | Heard_REEF_BNDY_LN.shp, Heard_REEF_PY.shp, 20 KB |
| 1214 | MCDONALD_QUICKBIRD_GIS | mcdonald_COASTLINE, _ISLAND, _OFFSHORE_RCK, _RIDGE, _ROCK shapefiles, 72 KB |
| 2812 | macca_coast_ambis_gis | macquarie_coastline_ambis, macquarie_island_ambis, macquarie_offshore_rocks_ambis shapefiles, 1.7 MB |
| 2112 | macquarie_quickbird_mapping | coastline.shp (line), 900 KB |

Field names for these need the files; the WFS layers above carry the
macca_coast_ambis_gis content already.

## Findings from the files

- Heard 2017-2019 (6018) is one GeoPackage with Coastline_py (3,324: Heard
  Island + 6 named islands + 3,317 offshore rocks), Coastline_ln (3,365),
  Landform_py, hydrology_ln/py and a partial vegetation_type_py. Captured
  2017-02-03 / 2019-01-13 / 2019-10-03, WorldView 30 cm, 1:1000. Revised
  2024-10-15, CC BY 4.0. Heard Island is a single polygon: no land/ice split.
- McDonald 2020 (6013): Coastline_ln 106, Coastline_py 75 (5 islands incl.
  McDonald Island and Flat Head, 70 offshore rocks), WV3 2020-06-25.
- The WFS himi_coastline_py (3,399) = 6018 (3,324) + 6013 (75) polygons.
  The WFS lines (3,453) do not equal the gpkg lines (3,365 + 106 = 3,471),
  so prefer the gpkgs as raw.
- Both new gpkgs share one schema (feat_type, certainty, status, date_capture,
  spat/att_reliability_date, date_flag, metadata_id, source, feature_source,
  spatial_method, attribute_source); this matches the WFS layers, not ADD.
- Legacy shapefiles use the SCAR feature-catalogue schema (FEAT_TYPE, UFI,
  Q_INFO, DATASET_ID, ...). 1214 mcdonald_RIDGE.shp is empty (0 features);
  2558 has no shapefile at all.
- Macquarie 2812: coastline 805 lines, island 189 polygons (incl. Bishop and
  Clerk 19, Judge and Clerk 10), offshore rocks 576. No capture dates.
  2112 QuickBird coastline: 176 lines, NW inset only.
