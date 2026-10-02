# aatcoast

Best available coastline polygons for the Australian Antarctic Territory and
the subantarctic islands (Heard, McDonald, Macquarie), assembled from
openly licensed sources (SCAR ADD, AADC), all CC BY 4.0.

Goal: a cached, versioned, topologically decomposed (arcs, levels of detail)
product in the style of hypertidy/cvr. Code and metadata live here; bulk
data outputs are intended for source.coop.

## Layout

- `acquisition/add/` - fetch script and field notes for SCAR ADD 7.12 coastlines
- `aadc-survey/` - fetch scripts and field notes for AADC datasets
- `reformat/` - v0 build of one combined "best value" polygon layer
  (EPSG:3031): script, schema, crosswalk, sources table, quicklook

## Data

v0 combined polygon layer (GeoPackage, layer `coastline_py`, EPSG:3031,
183 MB, sha256 `cbee9e8a09fc4766685d581781d18b0113da0663b6c4b6f0e46bbf16b8f3ed40`):

https://github.com/mdsumner/aatcoast/releases/download/v0/coastline_best_v0.gpkg

GDAL can read it in place:

```
ogrinfo -so /vsicurl/https://github.com/mdsumner/aatcoast/releases/download/v0/coastline_best_v0.gpkg coastline_py
```

## Status

v0 (2026-09-30): one polygon layer, one source per region, no splicing.
See `reformat/README.md` for decisions and what is deferred.
