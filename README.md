# Pilipinas

[![CI](https://github.com/denmarkmeralpis/pilipinas/actions/workflows/ci.yml/badge.svg)](https://github.com/denmarkmeralpis/pilipinas/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/pilipinas.svg)](https://badge.fury.io/rb/pilipinas)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A complete, read-only directory of Philippine geographic divisions:

```
Region  →  Province  →  City / Municipality  →  Barangay
(17)         (86)           (1,648)              (42,027)
```

## Features

- **Zero runtime dependencies** — pure Ruby + stdlib Psych (ships with Ruby).
- **Lazy-loaded & cached** — YAML is parsed once per class per process and held in a thread-safe, process-lifetime cache. Repeated calls are free.
- **O(1) look-ups** — separate hash indices keyed by code and by name; no linear scans.
- **Immutable value objects** — every entity instance is frozen. Safe to share across threads and fibers without copying.
- **Optional ActiveRecord integration** — a migration generator and Rake task seed the four `pilipinas_*` tables from the bundled YAML data.
- **Read-only by default** — persisted AR model instances raise `ActiveRecord::ReadOnlyRecord` on accidental writes; opt out per-class via `enforce_readonly = false`.
- **Test helper included** — `require 'pilipinas/testing/rspec'` disables the read-only guard for the entire RSpec suite with one line.
- **Ruby ≥ 3.4** required; developed against Ruby 4.0.

---

## Installation

Add this line to your application's Gemfile:

```ruby
gem "pilipinas"
```

Then run:

```sh
bundle install
```

Or install directly:

```sh
gem install pilipinas
```

---

## Usage

### Require

```ruby
require "pilipinas"
```

Rails applications load the gem automatically via Bundler.

---

### Regions

```ruby
# All 17 regions (returns a frozen Array)
Pilipinas::Region.all            # => [#<Region code="1" name="NCR…">, …]
Pilipinas::Region.count          # => 17
Pilipinas::Region.first          # => #<Region …>
Pilipinas::Region.last           # => #<Region …>

# Find by code (O(1), case-insensitive)
Pilipinas::Region.find_by(code: "17744")
Pilipinas::Region.find_by_code("17744")

# Find by name (O(1), case-insensitive)
Pilipinas::Region.find_by(name: "REGION V (Bicol Region)")
Pilipinas::Region.find_by_name("region v (bicol region)")   # same result

# Traverse down the hierarchy
region = Pilipinas::Region.find_by(name: "REGION V (Bicol Region)")
region.provinces   # => [#<Province …>, …]
```

---

### Provinces

```ruby
Pilipinas::Province.all          # => Array of 86 Province objects
Pilipinas::Province.count        # => 86

province = Pilipinas::Province.find_by(name: "CAMARINES SUR")
province.cities                  # => Array of City objects
```

---

### Cities / Municipalities

```ruby
Pilipinas::City.all              # => Array of 1,648 City objects
Pilipinas::City.count            # => 1648

city = Pilipinas::City.find_by(name: "NAGA CITY")
city.barangays                   # => Array of Barangay objects
```

---

### Barangays

```ruby
Pilipinas::Barangay.all          # => Array of 42,027 Barangay objects
Pilipinas::Barangay.count        # => 42027

Pilipinas::Barangay.find_by(code: "21687")
Pilipinas::Barangay.find_by(name: "Casay")
```

---

### Entity interface

Every entity object exposes:

| Method     | Returns  | Description                         |
|------------|----------|-------------------------------------|
| `#code`    | `String` | Unique geographic code              |
| `#name`    | `String` | Human-readable name                 |
| `#to_s`    | `String` | `"Region(code: 1, name: NCR…)"`     |
| `#inspect` | `String` | `#<Region code="1" name="NCR…">`    |
| `#==`      | `Boolean`| Equality by class + code            |
| `#frozen?` | `true`   | Always true — instances are frozen  |

---

### Supported find_by attributes

Both `find_by(attr: value)` and `find_by_attr(value)` accept:

| Attribute | Notes                  |
|-----------|------------------------|
| `:code`   | Geographic code string |
| `:name`   | Human-readable name    |

Any other attribute raises `Pilipinas::UnknownAttribute`.

---

### Error classes

| Class                         | Superclass         | Raised when                          |
|-------------------------------|--------------------|--------------------------------------|
| `Pilipinas::Error`            | `StandardError`    | Base class for all Pilipinas errors  |
| `Pilipinas::UnknownAttribute` | `Pilipinas::Error` | Unsupported attribute in `find_by_*` |

---

## Rails / ActiveRecord integration (optional)

The gem ships with an optional database back-end for applications that prefer SQL queries over in-memory look-ups.

### 1. Generate the migration

```sh
rails generate pilipinas:migration
rails db:migrate
```

This creates four tables: `pilipinas_regions`, `pilipinas_provinces`, `pilipinas_cities`, `pilipinas_barangays`.

### 2. Seed the tables

```sh
rake pilipinas:load
```

### 3. Use the AR models

```ruby
region   = Pilipinas::Db::Region.find_by(code: "17744")
region.provinces.count   # ActiveRecord query

province = Pilipinas::Db::Province.find_by(name: "CAMARINES SUR")
province.cities          # has_many association
```

> **Note:** The AR models are auto-loaded and require `activerecord` to be available.

### Read-only behaviour

All four `Pilipinas::Db::*` models are **read-only by default**. Any attempt to call `update!`, `save`, or `destroy` on a persisted record raises `ActiveRecord::ReadOnlyRecord`. This is intentional — the pilipinas tables are static reference data that should never be mutated after seeding.

New (unsaved) records are always writable, so `create!` works normally in the Loader and in test factories.

#### Opting a subclass out of read-only enforcement

If your application inherits from a Pilipinas DB model and legitimately needs write access, set `enforce_readonly` to `false` on the subclass:

```ruby
class Locations::Barangay < Pilipinas::Db::Barangay
  self.enforce_readonly = false
end
```

This does not affect the parent class or any other model.

---

## Testing

The gem ships a ready-made RSpec helper that turns off the read-only guard for the entire test suite — no stubbing required.

```ruby
# spec/rails_helper.rb  (or spec/support/pilipinas.rb)
require 'pilipinas/testing/rspec'
```

This sets `enforce_readonly = false` on all four models (`Region`, `Province`, `City`, `Barangay`) inside a `before(:suite)` hook, so FactoryBot factories, fixtures, and any spec that writes to pilipinas tables work without extra setup.

If you only need writable records in a specific context:

```ruby
around do |example|
  Locations::Barangay.enforce_readonly = false
  example.run
ensure
  Locations::Barangay.enforce_readonly = true
end
```

---

## Advanced

### Cache management

The in-memory cache is global to the process. In long-running processes the data never reloads (intentional — YAML files are static). To force a reload (e.g. in tests):

```ruby
Pilipinas::Cache.clear
```

### Thread-safety

All class-level state is initialised through `Pilipinas::Cache`, which uses a `Mutex` with double-checked locking. Entity instances are frozen. The gem is safe to use in multi-threaded applications (Puma, Sidekiq, etc.) without additional synchronisation.

---

## Development

```sh
git clone https://github.com/denmarkmeralpis/pilipinas
cd pilipinas
bin/setup          # install dependencies
bundle exec rake   # run the full test suite
bin/console        # start an IRB session with the gem loaded
```

### Running tests

```sh
bundle exec rspec                     # all specs
bundle exec rspec spec/pilipinas/     # unit specs only
bundle exec rubocop                   # lint
```

---

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/denmarkmeralpis/pilipinas).

Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

---

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).

---

## Acknowledgements

The data used in this gem is from `gem pinas`. Kudos!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/denmarkmeralpis/pilipinas. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Pilipinas project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/pilipinas/blob/master/CODE_OF_CONDUCT.md).
