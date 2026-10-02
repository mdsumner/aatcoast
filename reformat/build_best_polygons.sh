#!/usr/bin/env bash
# Build the "best value" combined coastline polygon layer (prototype v0).
# One layer, EPSG:3031, small common schema; see README.md and crosswalk.csv.
# Requires GDAL >= 3.6 (ogr2ogr, SQLite dialect). Each step is a single
# ogr2ogr call, so it ports directly to gdalraster::ogr2ogr().
set -euo pipefail

ROOT=${ROOT:-/mnt/project-files}
ADD=$ROOT/acquisition/add/raw/13c4d2f1-8903-4d7f-8977-592121975554/add_coastline_high_res_polygon_v7_12.gpkg
HEARD=$ROOT/aadc-survey/downloads/eds/6018_Heard_Island_topographic_data_2017_2019/Heard_Island_topographic_data_2017_2019.gpkg
MCDON=$ROOT/aadc-survey/downloads/eds/6013_McDonald_Island_Coastline_2020/McDonald_Island_Coastline_2020.gpkg
MACCA=$ROOT/aadc-survey/downloads/eds/2812_macca_coast_ambis_gis

OUT=${OUT:-$ROOT/reformat/out/coastline_best_v0.gpkg}
LYR=coastline_py
rm -f "$OUT"

# Common options: reproject to polar stereographic (ADD is already 3031),
# linearise any curve geometries, force MultiPolygon, rename geometry to geom.
COMMON=(-t_srs EPSG:3031 -nlt CONVERT_TO_LINEAR -nlt PROMOTE_TO_MULTI
        -nln "$LYR" -dialect SQLite)

# Output columns (all sources): surface, class, name, region, source,
# source_fid, source_date (Date, NULL when unknown).

# 0. Create the empty layer with the common schema (OGR SQL dialect, since
#    it can CAST to Date; the SQLite dialect cannot). Later appends write
#    'YYYY-MM-DD' text which OGR converts into the Date field.
ogr2ogr -f GPKG "$OUT" "$HEARD" -t_srs EPSG:3031 -nlt MULTIPOLYGON -nln "$LYR" -dialect OGRSQL \
  -lco GEOMETRY_NAME=geom -lco FID=fid \
  -sql "SELECT CAST(feat_type AS character(16)) AS surface,
               CAST(feat_type AS character(64)) AS class,
               CAST(feat_type AS character(128)) AS name,
               CAST(feat_type AS character(16)) AS region,
               CAST(feat_type AS character(16)) AS source,
               CAST(FID AS integer) AS source_fid,
               CAST(date_capture AS date) AS source_date
        FROM Coastline_py WHERE feat_type = '-'"

# 1. Heard Island 2017-19 (AADC eds 6018), 1:1000 from WV3 mosaic.
ogr2ogr -append -update "$OUT" "$HEARD" "${COMMON[@]}" \
  -sql "SELECT Shape AS geom, 'land' AS surface, feat_type AS class,
               NULLIF(NULLIF(TRIM(Name), ''), '<Null>') AS name, 'heard' AS region,
               'aadc_6018' AS source, OBJECTID + 0 AS source_fid,
               substr(date_capture, 1, 10) AS source_date
        FROM Coastline_py"

# 2. McDonald Islands 2020 (AADC eds 6013), WV3 30cm segmentation.
ogr2ogr -append -update "$OUT" "$MCDON" "${COMMON[@]}" \
  -sql "SELECT Shape AS geom, 'land' AS surface, feat_type AS class,
               NULLIF(NULLIF(TRIM(Name), ''), '<Null>') AS name, 'mcdonald' AS region,
               'aadc_6013' AS source, OBJECTID + 0 AS source_fid,
               substr(date_capture, 1, 10) AS source_date
        FROM Coastline_py"

# 3. Macquarie Island and islets 1:50k AMBIS (AADC eds 2812): islands, then
#    offshore rocks. No per-feature capture date (DB_DATE_CR is a load date).
#    Rocks marked 'Awash' keep that in class so they can be dropped later.
ogr2ogr -append -update "$OUT" "$MACCA/macquarie_island_ambis.shp" "${COMMON[@]}" \
  -sql "SELECT GEOMETRY AS geom, 'land' AS surface, FEAT_TYPE AS class,
               NULLIF(TRIM(SCAR_NAME), '') AS name, 'macquarie' AS region,
               'aadc_2812' AS source, UFI + 0 AS source_fid,
               NULL AS source_date
        FROM macquarie_island_ambis"
ogr2ogr -append -update "$OUT" "$MACCA/macquarie_offshore_rocks_ambis.shp" "${COMMON[@]}" \
  -sql "SELECT GEOMETRY AS geom, 'land' AS surface,
               CASE WHEN VISIBILITY = 'Awash' THEN FEAT_TYPE || ' (awash)'
                    ELSE FEAT_TYPE END AS class,
               NULLIF(TRIM(SCAR_NAME), '') AS name, 'macquarie' AS region,
               'aadc_2812' AS source, UFI + 0 AS source_fid,
               NULL AS source_date
        FROM macquarie_offshore_rocks_ambis"

# 4. Antarctica: SCAR ADD 7.12 high-res polygons (whole continent, not only
#    the AAT; filter on region/longitude downstream if wanted).
ogr2ogr -append -update "$OUT" "$ADD" "${COMMON[@]}" \
  -sql "SELECT geom, surface, surface AS class, NULL AS name,
               'antarctica' AS region, 'add_7.12_hr' AS source,
               fid + 0 AS source_fid, NULL AS source_date
        FROM add_coastline_high_res_polygon_v7_12"

# Summary
ogrinfo -q "$OUT" -dialect SQLite -sql \
  "SELECT region, source, surface, class, count(*) AS n,
          sum(source_date IS NULL) AS n_nodate
   FROM $LYR GROUP BY region, source, surface, class ORDER BY region, n DESC"
