# Validation recorded October 21, 2026

Validated on Ruby **3.4.11** (`2026-09-23 revision 592f1ffdb3`, arm64-darwin25). Base checkout was `a2af860eb7b0351e4fd62018911a3e588cba7809` on `develop`. Pin the final tested delivery SHA, not the base or moving branch.

| Check | Result |
| --- | --- |
| `bundle exec rake spec` | 121 examples, zero failures; includes existing legacy database tests |
| Ruby source-integrity and geography specs | Archived source digests match manifest and runtime metadata; unique identifiers, parent types, province-independent exceptions and nationwide traversal pass |
| RuboCop on changed runtime code, new specs and installed-gem smoke script, with `--cache false` | No offenses |
| `gem build pilipinas.gemspec` and local installation | Successful, version 2.0.0; no runtime gem dependencies |
| `scripts/smoke_installed.rb` in plain Ruby 3.4.11, outside Bundler | Nationwide unique traversal, exact counts, corrected name, postal matched/missing/ambiguous/rejected results, metadata and legacy mapping pass |
| Installed gem directory made read-only | Public lookups still pass |
| MIT license and moved historical database dump | SHA-256 identical to base checkout |

The source workbooks and HTML capture, generated geography/postal data and legacy mapping are unchanged by the tooling cleanup. The Ruby checks verify source integrity and the committed hierarchy; source-to-output extraction and per-region summary reconciliation follow the documented [data-refresh method](DATA.md#data-refresh-method).

The native app's mise configuration selects a different system Ruby outside this project. For isolated verification, capture the intended executable **before** changing directories:

```sh
pilipinas_ruby=$(ruby -rrbconfig -e 'puts RbConfig.ruby')
"$pilipinas_ruby" -v # verify 3.4.11
gem build pilipinas.gemspec --output /tmp/pilipinas-2.0.0.gem
gem install --local /tmp/pilipinas-2.0.0.gem --install-dir /tmp/pilipinas-check --no-document
env -u RUBYOPT -u BUNDLE_GEMFILE GEM_HOME=/tmp/pilipinas-check GEM_PATH=/tmp/pilipinas-check \
  "$pilipinas_ruby" scripts/smoke_installed.rb
```

PHLPost coverage limitations are part of the tested behavior: only 959 valid rows from the 960-row official capture, across 55 source province labels. The malformed Cajidiocan row remains a visible rejection. Missing ZIP coverage is not filled from other sources. See [DATA.md](DATA.md) and [consumer handoff](CONSUMER.md).

DMPI forms, saved addresses, customer data and package publication are outside this delivery. CI is configured for Ruby 3.4.11 and 4.0; local results above establish Ruby 3.4.11 verification. Check the delivery commit's GitHub Actions run for remote results.
