# Data provenance and maintenance

## PSGC

Publisher: **Philippine Statistics Authority (PSA)**. Snapshot/publication date in workbook Metadata: **30 September 2026**. Release date: **12 October 2026**, reference **2026-331**. Retrieved **21 October 2026**.

- [Dated release and official counts](https://psa.gov.ph/classification/psgc/node/1684084314)
- [Official directory and latest-publication listing](https://psa.gov.ph/classification/psgc)
- [PSGC 3Q 2026 Publication Datafile](https://psa.gov.ph/system/files/scd/PSGC-3Q-2026-Publication-Datafile.xlsx)
- [National and Provincial Summary](https://psa.gov.ph/system/files/scd/PSGC-3Q-2026-National-and-Provincial-Summary.xlsx)
- [PSA terms: CC BY 4.0 unless otherwise stated](https://psa.gov.ph/terms-of-use)
- [CC BY 4.0 license](https://creativecommons.org/licenses/by/4.0/)

The workbook's Metadata says access constraints are none, requires acknowledgement of PSA as the source, and distributes PSGC without warranty. PSA does not endorse this gem. The original source workbooks are committed under `sources/`; their SHA-256 hashes are recorded in `sources/manifest.json` and runtime metadata.

The data comes from the workbook's `PSGC` sheet. It preserves ten-digit PSGC text and supplied nine-digit correspondence codes. Correspondence codes remain absent where PSA leaves them blank. Surrounding display-name whitespace and, for Lucena only, the attached `a/` footnote marker are removed. Changed names retain `source_name`; Lucena's explanatory note is retained verbatim as data. Population, income and urban/rural classifications are not part of this lookup API.

Parents resolve by PSGC code structure against complete record sets, never by names or a preceding spreadsheet row. Province administrative membership excludes HUC/ICC cities; `psgc_province_code` retains ICC statistical code groupings. Manila barangays retain their SubMun parent and city ancestor. Two source rows with no geographic level, Isabela's non-province grouping and the SGA, become `Area` records. They do not increase province totals. See README for traversal semantics and PSA's Lucena caveat.

The snapshot was reconciled against **every region's independent National Summary counts** and the separate National and Provincial Summary workbook. Totals are 18 regions, 82 provinces, 149 cities (33 HUC, 5 ICC, 111 CC), 1,493 municipalities and 42,010 barangays. Fourteen Manila districts and two areas are counted separately. Ruby tests check source hashes, duplicate and malformed identifiers, parent types, cross-region ancestry, explicit province-independent cases, reverse relationships and nationwide traversal without duplicates.

## Postal

Publisher: **Philippine Postal Corporation (PHLPost)**. [Official ZIP Code Locator](https://phlpost.gov.ph/zip-code-locator/), retrieved **21 October 2026**. The page does not identify a publication or effective date, so metadata uses `publication_date: null` and records retrieval separately. Its footer states that content is public domain unless otherwise stated; the original page also carries PHLPost's copyright notice. Both are preserved in the archived HTML.

The committed capture `sources/phlpost-2026-10-21.html` is the actual HTTP response, not a third-party ZIP list. An HTML parser extracts only `table#offices`, decodes entities and normalizes cell whitespace. All four source labels (region, province, locality, ZIP) are preserved. It contains **960 rows, 55 province labels**, and has significant coverage gaps. In particular, Metro Manila has only Pandacan; several provinces are absent. This is not a nationwide postal coverage claim.

One source row, Romblon / Cajidiocan, has `Cajidiocan` in the ZIP column. It is excluded from the 959 valid ZIP rows and retained with a reason in `lib/data/postal_rejections.json`. Lookup returns it through `rejected_rows`. Identical postal rows are deduplicated only in runtime candidates. Repeated names and different source rows remain candidates, never first-match guesses.

The postal API does not link postal coverage to PSGC membership. PHLPost retains historical regional/provincial names and labels for districts, institutions and delivery areas. Consumers must use source labels, keep missing/ambiguous results visible, and allow a manually entered ZIP. No third-party source fills these gaps.

## Data-refresh method

The committed snapshot is the lookup input. Source captures and the transformation contract below allow a maintainer to repeat the extraction with their chosen spreadsheet/HTML tools; this gem does not ship a data-import program. Work on copies and retain the original source bytes. Read stored workbook values as text without recalculating formulas or coercing leading-zero identifiers to numbers.

1. In the publication workbook's `PSGC` sheet, use column B for `code`, C for `name`, D for optional `correspondence_code`, E for `level`, and G for optional `city_class`. Keep valid ten-digit coded records in source order. Separate `Reg`, `Prov`, `City`/`Mun`, `Bgy`, and `SubMun` into `regions.json`, `provinces.json`, `cities.json`, `barangays.json`, and `submunicipalities.json`. Reject unknown levels and duplicate codes. The only unclassified coded rows in this snapshot are `0990100000` and `1999900000`; preserve them as `Area` in `areas.json`. Review any newly unclassified row explicitly.
2. Apply the name and correspondence-code rules above. Retain `source_name` whenever the displayed name changes and Lucena's source note as `note`.
3. Resolve ancestors against the complete code set. A non-region's first two digits identify its region. A city/municipality's first five digits followed by five zeros identify its province or recognized area grouping. Retain a province grouping as `psgc_province_code`; assign `province_code` only for administrative membership, excluding HUC/ICC cities. Ordinary cities and municipalities must have a province. The explicit exceptions are HUC/ICC cities, cities/municipalities under a recognized `Area`, and Pateros (`1381701000`) in NCR. Never fall back silently to a region when a province is absent.
4. Set a province/area's `parent_code` to its region; a city's/municipality's to its administrative province, recognized area, or explicit independent-region parent. A Manila SubMun's first five digits followed by five zeros identify its city. A barangay's first seven digits followed by three zeros identify its City/Mun/SubMun parent. Retain each barangay's `city_code`, optional `submunicipality_code`, and its city's administrative `province_code` or `area_code`. Reject missing parents, wrong levels and cross-region relationships.
5. Reconcile Prov/City/Mun/Bgy counts for every region against the publication's `National Summary`, and national totals against the separate summary workbook's `Provincial Summary`. Totals alone cannot establish a valid hierarchy; check every parent as above.
6. Extract only PHLPost `table#offices`, preserving its four columns as `region`, `province`, `locality`, `zip_code`; decode HTML entities and normalize cell whitespace. Retain original row order and duplicate rows. Put rows with a four-digit ZIP in `postal.json`; retain malformed rows and their reason in `postal_rejections.json`. Check the captured row count, never join to PSGC by names, and leave uncovered localities missing.
7. Rebuild `legacy_mapping.json` from the unchanged `sources/legacy-compact.json`, matching only verified correspondence codes to records of the same kind (allow old cities to map to SubMun). Retain every historical record with `matched`, `ambiguous` or `missing` status and all candidates. Compose `metadata.json` from the source manifest plus counts and city classifications. Use the current JSON field schema, UTF-8 and one record per line; preserve source order for reviewable diffs.

Run `bundle exec rake spec` on Ruby 3.4.11 to verify the committed data and source hashes locally. The tests also run in CI; they do not regenerate files or independently parse the workbooks. Review source-to-output transformations and independent summary reconciliation as part of each data refresh.

## Import a later snapshot

1. Check PSA's official directory and dated release for the latest **available** publication. Record snapshot date, release date, source URL and retrieval date separately. Download the official workbook and summary into `sources/`. PSA returned HTTP 403 to curl for this import; the official linked files were downloaded in a browser after its normal verification completed.
2. Capture PHLPost independently with `curl -fL https://phlpost.gov.ph/zip-code-locator/ -o sources/phlpost-YYYY-MM-DD.html`. Do not assume it has the same date or geographic names as PSGC.
3. Update `sources/manifest.json`: source filenames, URLs, dates, actual postal table row count and SHA-256 values (`shasum -a 256 sources/<file>`). Keep `publication_date` null unless PHLPost supplies one. Archive new source bytes before import. Keep the historical `legacy-compact.json` baseline unchanged.
4. Repeat the data-refresh method above. Review unexpected schemas, new area types, changed classifications and name notes in source documents before adapting explicit transformation rules. Do not bypass hierarchy or regional count validation. Review all rejected postal rows and missing coverage.
5. Review the data diff, totals, mappings and tests for administrative changes. Update documented dates/counts and snapshot-specific regression expectations. Run the Ruby 3.4.11 suite. Build/install the gem and smoke-test outside Bundler to verify packaged data and no runtime gem dependencies.
6. Commit the sources, manifest, generated data, code and documentation together. Record the tested full SHA for consumers. A RubyGems publication or release tag is not required; this repository's `v*` tag workflow publishes, so do not create a release tag casually.

## Historical data and identifiers

`lib/data/legacy/pilipinas_data.yml` is the unchanged historical `gem pinas`-derived ActiveRecord fixture dump, moved into a clearly named legacy directory. It is not refreshed PSGC data. `sources/legacy-compact.json` preserves all 43,778 original compact file-backed records and their old internal identifiers. An old nine-digit official code is included only where the original full dump agrees on internal ID **and name**. The refresh maps those codes to the new workbook's correspondence column, with explicit missing results. See [UPGRADING.md](UPGRADING.md). No application records are migrated or rewritten by this gem update.
