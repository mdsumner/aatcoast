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

## Status

v0 (2026-09-30): one polygon layer, one source per region, no splicing.
See `reformat/README.md` for decisions and what is deferred.
