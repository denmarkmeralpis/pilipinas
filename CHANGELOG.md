# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- `lib/pilipinas/testing/rspec.rb` — a ready-made RSpec helper that disables
  the read-only guard on all four DB models for the entire test suite.
  Require it once in `rails_helper.rb`:
  ```ruby
  require 'pilipinas/testing/rspec'
  ```
- Spec coverage for `StaticRecord` — 8 examples covering default behaviour,
  `enforce_readonly = false`, subclass inheritance, and class-level isolation.

### Changed

- `readonly?` now gates on `self.class.enforce_readonly && !new_record?` instead
  of unconditionally returning `!new_record?`.

---

## [1.0.0] - 2026-05-12

Complete rewrite of the gem. Zero runtime dependencies.

### Added

- In-memory layer with thread-safe `Pilipinas::Cache` (Mutex + double-checked
  locking) and O(1) look-ups via separate code/name hash indices.
- Immutable value objects — every entity instance is frozen.
- `Pilipinas::Region`, `Province`, `City`, `Barangay` with `.all`, `.count`,
  `.first`, `.last`, `.find_by`, `.find_by_code`, `.find_by_name`.
- Hierarchy traversal: `region.provinces`, `province.cities`, `city.barangays`.
- Optional ActiveRecord layer (`Pilipinas::Db::*`) with memory-efficient scopes
  (`.lite`, `.by_code`, `.by_name`, `.find_lite_by_code`, `.find_lite_by_name`).
- `StaticRecord` concern: disables STI, adds lean SELECT scopes, enforces
  read-only on persisted records.
- Migration generator (`rails generate pilipinas:migration`) and
  `rake pilipinas:load` seeding task.
- Full RSpec suite (57 examples).
- GitHub Actions CI pipeline.

### Changed

- Requires Ruby ≥ 3.4 (developed against Ruby 4.0).
- Removed all runtime gem dependencies (previously depended on `yaml_db` and
  others).

---

## [0.0.1] - 2019-01-26

### Added

- Initial release.
- YAML data for Philippine regions, provinces, cities, and barangays.
- ActiveRecord models backed by `pilipinas_*` tables.
- Migration template and Rake loader task.
- Rails generator for migrations.
- Railtie for automatic Rake task loading in Rails apps.

[1.1.0]: https://github.com/denmarkmeralpis/pilipinas/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/denmarkmeralpis/pilipinas/compare/v0.0.1...v1.0.0
[0.0.1]: https://github.com/denmarkmeralpis/pilipinas/releases/tag/v0.0.1
