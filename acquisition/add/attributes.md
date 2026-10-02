# ADD 7.12 coastline: layers and fields

Confirmed 2026-09-30 against the downloaded GeoPackages in raw/ (read with
sqlite3; gpkg_contents, gpkg_geometry_columns, pragma table_info). Earlier
version of this file came from the ArcGIS Living Atlas FeatureServer; the
GeoPackages agree with it on names, types, vocabularies and counts.

All layers: CRS EPSG:3031, geometry column `geom`, primary key `fid`.
Each gpkg also has a `layer_styles` table (QGIS 3.34 style), not data.

## High-res coastline polygons (13c4d2f1..., add_coastline_high_res_polygon_v7_12)

- MULTIPOLYGON, 17,700 features
- surface TEXT(254): land 17,269; ice shelf 330; rumple 64; ice tongue 37
- no other attributes (no provenance on polygons)

## High-res coastline lines (dbaf29f5..., add_coastline_high_res_line_v7_12)

- MULTILINESTRING, 36,842 features
- surface TEXT(80): rock coastline 25,302; ice coastline 8,716;
  grounding line 1,513; rock against ice shelf 684; ice shelf and front 565;
  ice rumples 62
- sourcedate DATE: 1973-11-13 .. 2026-04-08, null in 8,166
- sourceprec TEXT(80): day 26,871; year 1,805; null 8,166
- source TEXT(187): 131 values, top WV01 12,820, AUS 4,420, WV02 4,332,
  QB02 2,925; null 2,312
- updater TEXT(80): 23 values (Risse, APRC, Krenzelok, lgerrish, MJRU, ...)
- revdate DATE: 1992-01-02 .. 2026-04-10; revprec TEXT(80): month/day/year
- lineage TEXT(99): 621 values (image ids, "Digitized from LIMA", ...),
  null 9,382

## Medium-res polygons (c9c6d671..., add_coastline_medium_res_polygon_v7_12)

- MULTIPOLYGON, 2,216 features; surface: land 1,786; ice shelf 329;
  rumple 64; ice tongue 37

## Medium-res lines (37ad06ff..., add_coastline_medium_res_line_v7_12)

- MULTILINESTRING, 17,809 features; same 8 attribute columns as high-res
  lines; sourcedate 1973-11-13 .. 2026-04-08, null 4,150

## Differences from the FeatureServer version

- Field order in the gpkg lines is surface, sourcedate, sourceprec, source,
  updater, revdate, revprec, lineage (updater before revdate).
- No FID/Shape__Area/Shape__Length service fields.
- sourcedate/revdate are real DATE columns.

## Reformatting notes for later

- Polygon 'surface' and line 'surface' use different vocabularies
  (e.g. 'rumple' vs 'ice rumples', 'ice shelf' vs 'ice shelf and front').
  A crosswalk is needed before attaching line provenance to arcs.
- Polygons carry no date/source; the arc decomposition can inherit those from
  the matching line segments, since lines are the provenance-bearing layer.
- *prec fields are precision qualifiers for the adjacent dates (text).
- AADC publishes its own AAT compilation with per-feature provenance on
  polygons too (WFS Mapping:coastline_py); see
  ../../aadc-survey/downloads/README.md.
