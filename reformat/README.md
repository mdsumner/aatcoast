# Reformat stage: one "best value" coastline polygon layer (v0 prototype)

Built 2026-09-30 by `build_best_polygons.sh` (GDAL 3.8 ogr2ogr only; each
step is one ogr2ogr call, so it ports 1:1 to `gdalraster::ogr2ogr()`).

Output: `out/coastline_best_v0.gpkg`, layer `coastline_py`, 21,864
MultiPolygons, all valid (ST_IsValid), no overlaps between features within
the subantarctic regions. Quicklook: `out/quicklook_v0.png`.

## Decisions (v0)

- **One layer**, polygons only. Lines stay raw for now; they carry ADD's
  per-segment provenance and come back in the arc-decomposition stage.
- **CRS EPSG:3031.** ADD's continent polygon contains the South Pole, so it
  cannot be held in lon/lat without breaking; the subantarctic islands
  (53-55 S) reproject into 3031 without trouble.
- **One source per region, no mixing.** Nothing is clipped or spliced:
  each region comes whole from its best source.
- **ADD kept circumpolar**, not clipped to the AAT. Clipping by longitude
  (45-160 E minus Adelie Land 136-142 E) is a one-line filter later.
- Curves: none of the raw GPKG/shapefile inputs contain curve geometries
  (only the WFS copies do), but `-nlt CONVERT_TO_LINEAR` stays in as a guard.

## Schema

| column       | type    | meaning |
|--------------|---------|---------|
| fid          | integer | row id in this build (not stable across versions) |
| surface      | text    | ADD polygon vocabulary: land, ice shelf, ice tongue, rumple |
| class        | text    | source's own feature type (ADD surface, or AADC feat_type) |
| name         | text    | place name where the source has one, else NULL |
| region       | text    | antarctica, heard, mcdonald, macquarie |
| source       | text    | key into `sources.csv` |
| source_fid   | integer | feature id in the raw source (ADD fid, AADC OBJECTID / UFI) |
| source_date  | date    | capture date where the source gives one per feature, else NULL |

Dataset-level facts (title, scale, licence, uuid, raw file, checksum
manifest) live once in `sources.csv`, not repeated on each row.

## Crosswalk

See `crosswalk.csv`. Everything in the subantarctic sources maps to
`surface = land` (Heard's glaciers are grounded ice, which ADD also calls
land). The original type survives in `class`, e.g. Island, Offshore rock,
Offshore rock (awash).

## Counts

| region     | source      | n      | classes |
|------------|-------------|--------|---------|
| antarctica | add_7.12_hr | 17,700 | land 17,269; ice shelf 330; rumple 64; ice tongue 37 |
| heard      | aadc_6018   | 3,324  | Offshore rock 3,317; Island 7 |
| macquarie  | aadc_2812   | 765    | Offshore rock 461; Offshore rock (awash) 115; Island 189 |
| mcdonald   | aadc_6013   | 75     | Offshore rock 70; Island 5 |

`source_date` is filled for Heard and McDonald only. ADD polygons carry no
dates (the lines do), and 2812's DB_DATE_CR is a database load date.

## Deferred (revisit when v0 is not enough)

- Macquarie NW QuickBird inset (eds 2112) is **lines only**. Using it means
  polygonising and splicing into the 1:50k island; left out of v0.
- ADD provenance (sourcedate, source image) onto polygon edges: comes from
  the line layer during arc decomposition.
- Heard hydrology (lagoons, water bodies) and `Landform_py` inland islands
  are not coastline and are not used.
- ADD medium-res polygons as a lower level of detail, instead of or as well
  as simplifying the arcs ourselves.
- Heard source quirk: its `Name` field uses the literal string `<Null>`;
  the script maps that, and empty strings, to NULL.
