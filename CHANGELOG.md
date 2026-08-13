# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.6] - 2026-08-13

### Dependencies

- Updated Rails components (`actionpack`, `actionview`, `activemodel`, `activerecord`, `activesupport`, `railties`) to 8.1.3.1.
- Updated `erb` to 6.0.7, `io-console` to 0.9.2, `json` to 2.21.2, `rack` to 3.2.7, `rbs` to 4.1.3, `reline` to 0.7.0, `rubocop` to 1.89.0, `sqlite3` to 2.9.6, and `zeitwerk` to 2.8.3.

---

## [1.1.5] - 2026-07-28

### Changed

- CI workflow now uses `actions/checkout@v7` and `codecov/codecov-action@v7`.
- CI now generates an LCOV coverage report (`coverage/lcov/pilipinas.lcov`) via `simplecov-lcov` and uploads it to Codecov alongside the existing HTML/console formatters.

### Dependencies

- Updated `concurrent-ruby` to 1.3.8, `erb` to 6.0.6, `json` to 2.21.1, `loofah` to 2.25.2, `parser` to 3.3.12.0, `rbs` to 4.1.0, `rubocop` to 1.88.2, `rubocop-ast` to 1.50.0, `language_server-protocol` to 3.17.0.6, and `rails-html-sanitizer` to 1.7.1.
- Removed unused transitive dependencies (`date`, `psych`, `stringio`) no longer required by `rdoc`.

---

## [1.1.4] - 2026-06-26

### Changed

- `rake pilipinas:load` now wraps the entire seed transaction in `ActiveRecord::Base.uncached` so a long-running Rails process cannot serve stale query-cache hits during seeding.
- `Loader` clears the per-connection query cache after every `bulk_insert` batch and in the `run` `ensure` block, preventing cached bind-values from accumulating across batches.
- Batch arrays are now cleared in-place (`batch.clear`) instead of being replaced by a new object, allowing Ruby's GC to reclaim the memory sooner.
- The full location records table is released in `run`'s `ensure` block so memory is freed even if an exception interrupts seeding.

### Dependencies

- Updated `json` to 2.19.9.

---

## [1.1.3] - 2026-06-13

### Fixed

- `rake pilipinas:load` now upserts ActiveRecord seed rows by `location_id` instead of `code`, matching the stable identifier from `lib/data/pilipinas_data.yml`.
- `rails generate pilipinas:code_indexes` now generates a migration that adds unique `location_id` indexes to all four `pilipinas_*` tables, matching the loader's upsert conflict target.

### Changed

- Updated loader upgrade guidance and README wording to reference the required `location_id` unique indexes.

### Tests

- Added regression coverage that asserts `Loader.bulk_insert` uses `location_id` as the `upsert_all` unique key and reports the matching missing-index guidance.

---

## [1.1.2] - 2026-06-12

### Fixed

- `rake pilipinas:load` now seeds the ActiveRecord tables from `lib/data/pilipinas_data.yml`, the complete bundled data source. Previously the loader used the compact file-backed YAML files, so database rows were populated with only `code` and `name` while columns such as `location_id`, `parent_id`, `lft`, `rgt`, coordinates, and classification fields remained `NULL`.

- Re-running `rake pilipinas:load` now removes stale compact rows created by earlier loader versions. This fixes cases where old rows such as provinces with `location_id: nil` remained in the database because their compact internal codes did not match the full PSA-style codes used by `pilipinas_data.yml`.

### Changed

- Improved loader memory behavior by transforming rows directly from the parsed full-data table and keeping only the current insert batch in memory.

### Tests

- Added regression coverage for complete-column seeding, stale compact-row cleanup, legacy seed behavior, and exact batch-boundary inserts.

---

## [1.1.1] - 2026-06-11

### Added

- `rails generate pilipinas:code_indexes` — new migration generator that adds `UNIQUE` indexes on the `code` column to all four `pilipinas_*` tables. Run this if your database was created with a pre-1.0 migration and `rake pilipinas:load` raises `ArgumentError: No unique index found for code`.

### Fixed

- `Loader.bulk_insert` now rescues the bare `ArgumentError` raised by `upsert_all` when the unique index on `code` is absent, and re-raises it as a descriptive `Pilipinas::Error` that tells the user exactly which commands to run (`rails generate pilipinas:code_indexes && rails db:migrate`). Previously the error surfaced as an unguided `ArgumentError` from deep inside ActiveRecord.

---

## [1.1.0] - 2026-05-13

### Added

- `enforce_readonly` class attribute on the `StaticRecord` concern (default: `true`).
  Subclasses can opt out of the read-only guard without stubbing:
  ```ruby
  class Locations::Barangay < Pilipinas::Db::Barangay
    self.enforce_readonly = false
  end
  ```
- `lib/pilipinas/testing/rspec.rb` — a ready-made RSpec helper that disables the read-only guard on all four DB models for the entire test suite. Require it once in `rails_helper.rb`:
  ```ruby
  require 'pilipinas/testing/rspec'
  ```
- Spec coverage for `StaticRecord` — 8 examples covering default behaviour, `enforce_readonly = false`, subclass inheritance, and class-level isolation.

### Changed

- `readonly?` now gates on `self.class.enforce_readonly && !new_record?` instead of unconditionally returning `!new_record?`.

---

## [1.0.0] - 2026-05-12

Complete rewrite of the gem. Zero runtime dependencies.

### Added

- In-memory layer with thread-safe `Pilipinas::Cache` (Mutex + double-checked locking) and O(1) look-ups via separate code/name hash indices.
- Immutable value objects — every entity instance is frozen.
- `Pilipinas::Region`, `Province`, `City`, `Barangay` with `.all`, `.count`, `.first`, `.last`, `.find_by`, `.find_by_code`, `.find_by_name`.
- Hierarchy traversal: `region.provinces`, `province.cities`, `city.barangays`.
- Optional ActiveRecord layer (`Pilipinas::Db::*`) with memory-efficient scopes (`.lite`, `.by_code`, `.by_name`, `.find_lite_by_code`, `.find_lite_by_name`).
- `StaticRecord` concern: disables STI, adds lean SELECT scopes, enforces read-only on persisted records.
- Migration generator (`rails generate pilipinas:migration`) and `rake pilipinas:load` seeding task.
- Full RSpec suite (57 examples).
- GitHub Actions CI pipeline.

### Changed

- Requires Ruby ≥ 3.4 (developed against Ruby 4.0).
- Removed all runtime gem dependencies (previously depended on `yaml_db` and others).

---

## [0.0.1] - 2019-01-26

### Added

- Initial release.
- YAML data for Philippine regions, provinces, cities, and barangays.
- ActiveRecord models backed by `pilipinas_*` tables.
- Migration template and Rake loader task.
- Rails generator for migrations.
- Railtie for automatic Rake task loading in Rails apps.

[1.1.6]: https://github.com/denmarkmeralpis/pilipinas/compare/v1.1.5...v1.1.6
[1.1.5]: https://github.com/denmarkmeralpis/pilipinas/compare/v1.1.4...v1.1.5
[1.1.4]: https://github.com/denmarkmeralpis/pilipinas/compare/v1.1.3...v1.1.4
[1.1.3]: https://github.com/denmarkmeralpis/pilipinas/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/denmarkmeralpis/pilipinas/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/denmarkmeralpis/pilipinas/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/denmarkmeralpis/pilipinas/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/denmarkmeralpis/pilipinas/compare/v0.0.1...v1.0.0
[0.0.1]: https://github.com/denmarkmeralpis/pilipinas/releases/tag/v0.0.1
