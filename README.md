# Pilipinas

[![CI](https://github.com/denmarkmeralpis/pilipinas/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/denmarkmeralpis/pilipinas/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Local, read-only Philippine geography from the **PSA PSGC as of September 30, 2026**, released October 12, 2026. Separately sourced PHLPost postal lookup returns candidates and explicit missing or ambiguous results. No database, API key, HTTP request, or runtime gem dependency is required.

| Geographic level | Snapshot total |
| --- | ---: |
| Regions | 18 |
| Administrative provinces | 82 |
| Cities | 149 |
| Municipalities | 1,493 |
| Barangays | 42,010 |
| Manila sub-municipal districts (separate from municipalities) | 14 |
| Non-province PSGC areas | 2 |

All counts reconcile to PSA's publication, including every regional summary. [Sources and data maintenance](docs/DATA.md), [2.0 upgrade guide](docs/UPGRADING.md), [consumer handoff](docs/CONSUMER.md).

## Installation

Ruby >= 3.4; tested on **Ruby 3.4.11**. Add the gem to your application's Gemfile:

```ruby
# Gemfile
gem 'pilipinas'
```

## Geography

```ruby
require 'pilipinas'

Pilipinas::Region.all    # frozen canonical records
Pilipinas::Region.count  # 18
Pilipinas::Province.count # 82
Pilipinas::City.count     # 1642: City and Mun levels combined
Pilipinas::Barangay.count # 42010

region = Pilipinas::Region.find_by_code('1400000000')
province = region.provinces.find { |p| p.name == 'Abra' }
town = province.cities.find { |c| c.name == 'Peñarrubia' }
town.barangays
barangay = town.barangays.first
barangay.city      # canonical town object
barangay.province  # Abra
barangay.region    # CAR
barangay.parent    # town, or a Submunicipality for Manila barangays
```

`code` is the official **ten-digit PSGC string**, including leading zeros. `correspondence_code` preserves the workbook's older nine-digit code where supplied. Never convert codes to integers. See the upgrade guide before replacing the old gem's internal IDs.

Every class supports `all`, `count`, `first`, `last`, `where`, `find_by`, `find_by_code` and `find_by_name`. Name matching ignores case, preserves accents and does not invent aliases. `where` returns every match; `find_by` returns `nil` for none and raises `Pilipinas::AmbiguousMatch` for several. Combine filters to disambiguate:

```ruby
Pilipinas::City.where(name: 'City of Naga') # two cities
Pilipinas::City.find_by(name: 'City of Naga', region_code: '0500000000')
Pilipinas::Barangay.where(name: 'Casay', city_code: '0501719000')
```

Supported attributes are listed in `Pilipinas::Base::ATTRIBUTES`, including `parent_code`, `region_code`, `province_code`, `city_code`, `submunicipality_code`, `area_code`, `level` and `city_class`. Invalid attributes raise `Pilipinas::UnknownAttribute`. `find_by({})` raises `ArgumentError`. Codes, names, objects, metadata, and returned collections are immutable. Parsed data and lookup indices are cached under a mutex; no files are written by queries. `Pilipinas::Cache.clear` clears only process memory.

## NCR, independent cities and special areas

`Region#cities` includes **all** cities and municipalities in a region. Iterating it and each city's `barangays` reaches every barangay exactly once, including those outside provincial administration.

- NCR has **no provinces**. Its 16 cities and Pateros are directly available through `Region#cities` and `cities_without_province`.
- `Province#cities` means administrative membership. HUC/ICC cities have `province_code == nil`; use `Region#cities` or `cities_without_province`. For ICC cities, `psgc_province_code` retains the workbook's statistical provincial code grouping without asserting administrative membership.
- Manila's 14 `Submunicipality` records are districts, not municipalities. `manila.submunicipalities` preserves them. `manila.barangays` includes all 897 barangays, while each barangay retains its district `parent_code` and `submunicipality_code`.
- `Area` represents the workbook's **Special Geographic Area** and **City of Isabela (Not a Province)**. Use `Region#areas`, `Area#cities`, and `City#area`. These are never included in `Province.all`. The SGA contains eight municipalities and 63 barangays.
- Lucena follows PSA's HUC classification for statistical purposes. Its `note` preserves PSA's caveat about legal status. Its display name omits the attached `a/` footnote marker; `source_name` preserves the original.

For a UI, either start with a region and select a city directly, or show provinces alongside a clearly labelled “Cities/municipalities without a province” option. Those UI groupings have no invented PSGC province identifiers.

## PHLPost ZIP candidates

```ruby
result = Pilipinas::Postal.lookup(locality: 'Pandacan', province: 'Metro Manila')
result.status      # :matched
result.suggestion  # '1011'
result.candidates  # frozen Entry objects: region, province, locality, zip_code

result = Pilipinas::Postal.lookup(locality: 'Santa Maria')
result.status      # :ambiguous
result.zip_codes   # ['8011', '2440']
result.suggestion  # nil

Pilipinas::Postal.lookup(locality: 'Makati', province: 'Metro Manila').status # :missing
Pilipinas::Postal.metadata # source URL, retrieval date; publication_date is nil
```

`locality:` is required. Optional `province:` and `region:` filters use the **PHLPost labels**, which can differ from PSGC names and current administrative regions. Only case and whitespace are normalized. There is no fuzzy match, automatic name conversion, PSGC-to-postal join, province default ZIP, or inferred barangay coverage. A single result identifies a source postal locality, not every address in a PSGC city.

**Source coverage is incomplete:** the October 21, 2026 PHLPost locator capture contains 960 rows across 55 province labels, with 959 valid ZIP rows. It supplies only Pandacan under Metro Manila and no Makati entry. Missing results therefore mean the captured source cannot supply a match, not that the place lacks a ZIP. The malformed Cajidiocan row is retained in `result.rejected_rows` with its rejection reason; no replacement ZIP was guessed. Several candidates never produce a suggestion, even if their ZIPs happen to agree. Consumers should permit manual ZIP entry and overrides.

## Legacy database integration

The optional `Pilipinas::Db::*`, generators, Rake loader, and `pilipinas/testing/rspec` helper remain for compatibility. **They use the historical `lib/data/legacy/pilipinas_data.yml` dump, not the refreshed PSGC directory.** The old nested-set IDs, coordinates, and classifications have not been invented for the new snapshot. Use the file-backed classes above for current geography; no seed or migration is needed. `require 'pilipinas'` and all current lookups leave application databases untouched. `rake pilipinas:load` remains an explicit legacy database write operation.

## Development

```sh
bundle install
bundle exec rake spec
gem build pilipinas.gemspec
```

CI runs the Ruby suite on Ruby 3.4.11 and 4.0 and checks the built gem. See [data maintenance](docs/DATA.md) before updating a snapshot. Bug reports and pull requests are welcome in the [project repository](https://github.com/denmarkmeralpis/pilipinas). Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## License and acknowledgements

The software remains under the [MIT License](LICENSE), copyright (c) 2018 Nujian Den Mark Meralpis. Original project: [denmarkmeralpis/pilipinas](https://github.com/denmarkmeralpis/pilipinas). The historical data used in this gem is from `gem pinas`. Kudos!

Current geography is adapted from the Philippine Statistics Authority's PSGC publication, with acknowledgement to PSA and its [CC BY 4.0 terms](https://psa.gov.ph/terms-of-use). Postal entries are separately attributed to the Philippine Postal Corporation (PHLPost); its captured page states public-domain content unless otherwise stated. Dataset provenance, source URLs, transformations and checksums are in [DATA.md](docs/DATA.md), `sources/manifest.json`, and `Pilipinas.metadata`. These dataset notices accompany the MIT software license.
