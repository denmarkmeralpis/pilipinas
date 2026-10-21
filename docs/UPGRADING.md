# Upgrading from 1.x to 2.0

This is a breaking data/identifier upgrade. Review consumers before changing the pinned dependency.

- The old file API's `code` values were internal row IDs such as `18817`; 2.0 uses PSA's ten-digit PSGC strings such as `0501724000`. The legacy database dump has a third identifier space: its nine-digit `code` and numeric `location_id`. Keep those spaces separate.
- Existing `Region`, `Province`, `City`, `Barangay`, `all`, `count`, `first`, `last`, `find_by`, `find_by_code`, `find_by_name`, `provinces`, `cities`, and `barangays` entry points remain. Names and totals now follow the dated publication. Name lookups can change spelling/order (for example, `NAGA CITY` becomes `City of Naga`). No undocumented alias is inferred.
- `where` supports multiple filters and repeated names. `find_by` now raises `Pilipinas::AmbiguousMatch` for duplicates instead of silently choosing the last record. Use official codes or a parent filter.
- Provinces now mean the 82 actual provinces. NCR's four old pseudo-provinces are removed. Manila districts move from `City` to `Submunicipality`. Region-to-city traversal covers NCR, HUC/ICC cities, Isabela and SGA municipalities. `parent_code` can identify a province, region, non-province area, city or Manila district. Use the explicit ancestor fields instead of assuming exactly four administrative levels.
- New `Pilipinas.metadata` identifies the exact source and dates. Arrays, metadata and record strings are frozen. Query calls never write to disk or to a database.
- Optional `Db` APIs keep using the unchanged historical dump. The new file API and legacy database are deliberately different datasets. Do not seed the legacy dump as a way to obtain the refreshed directory.

## Mapping old compact IDs

```ruby
mapping = Pilipinas.legacy_lookup(type: :cities, code: '18817')
# => { 'type'=>'cities', 'code'=>'18817', 'name'=>'NAGA CITY',
#      'correspondence_code'=>'051724000', 'status'=>'matched',
#      'candidates'=>[{'type'=>'cities', 'code'=>'0501724000'}] }

Pilipinas.legacy_lookup(type: :provinces, code: '2')['status'] # 'missing' (old NCR grouping)
```

`type` is one of `regions`, `provinces`, `cities`, `barangays`. All 43,778 old compact rows are in `lib/data/legacy_mapping.json`: **43,584 matched, 194 missing, zero ambiguous** in this snapshot. Candidate types can be `submunicipalities` for old Manila district records. A previously unknown old ID returns `nil`. The mapping is an explicit review aid, not an automatic alias for `.find_by_code`.

A match requires agreement between the historical compact ID/name and the old full dump, followed by a correspondence-code match in the new workbook. Changed or missing correspondence codes, removed/split units, old display groupings and unverified historical rows remain missing. Names are never used alone to assign a new official ID. Future snapshots may produce multiple candidates; the mapping schema preserves that ambiguity.

Keep original saved address strings and identifiers visible until the consuming application explicitly resolves them. A missing mapping must not erase or relabel an existing address. No changes to DMPI forms or saved customer data are included here.
