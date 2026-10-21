# Handoff for storyseller/dynamic#219

Dependency: [dreinavarro/pilipinas#1](https://github.com/dreinavarro/pilipinas/issues/1). The separate [DMPI integration ticket](https://github.com/storyseller/dynamic/issues/219) owns form changes, ZIP suggestions, saved-value fallback, and browser acceptance tests.

Use the **full tested commit SHA reported with this delivery**, rather than the moving `develop` branch. Gem version is 2.0.0; no public package publication is implied.

```ruby
gem 'pilipinas', git: 'https://github.com/dreinavarro/pilipinas.git', ref: '<tested full SHA>'
```

Run `bundle update pilipinas` in the consuming application's documented environment, preserving the explicit ref in its lockfile. No geography database migration, seed task, HTTP service, or runtime gem dependency is needed.

Use `Region#cities` for complete region traversal. If the form uses province/address groups, combine `region.provinces` with a clearly labelled group using `region.cities_without_province`; do not invent province identifiers. See README for NCR, districts, SGA and Isabela. Request only the selected city's `barangays` rather than embedding the nationwide collection repeatedly.

Use codes for choices, include parent filters for duplicate names, and retain unsupported saved values for manual correction. Postal queries use PHLPost's own labels; there is no automatic mapping from PSGC codes. `Postal::Result#suggestion` is populated only for one exact supported postal locality candidate. Handle `:missing` and `:ambiguous` with manual entry; a stale previous ZIP is not a supported match. Makati has no entry in this PHLPost capture, so the old sample's 1223 must not be treated as a nationwide city default from this gem.

Validation is recorded in [VALIDATION.md](VALIDATION.md): Ruby 3.4.11 full RSpec suite (including legacy DB compatibility), archived source integrity and nationwide hierarchy checks, and built-gem isolated smoke checks. The final pin SHA is supplied in the delivery message. See [DATA.md](DATA.md) for source dates and coverage limits and [UPGRADING.md](UPGRADING.md) for the internal-ID migration map. This ticket makes no changes to DMPI itself.
