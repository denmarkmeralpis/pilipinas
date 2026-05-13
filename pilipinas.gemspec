# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pilipinas/version"

Gem::Specification.new do |spec|
  spec.name        = "pilipinas"
  spec.version     = Pilipinas::VERSION
  spec.authors     = ["Nujian Den Mark Meralpis"]
  spec.email       = ["denmarkmeralpis@gmail.com"]
  spec.summary     = "Complete directory of Philippine regions, provinces, cities, and barangays"
  spec.description = "Read-only, file-backed directory of Philippine geographic divisions. " \
                     "Zero runtime dependencies. Lazy-loaded, cached, and thread-safe."
  spec.homepage    = "https://github.com/denmarkmeralpis/pilipinas"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.4"

  spec.metadata = {
    "allowed_push_host"     => "https://rubygems.org",
    "homepage_uri"          => spec.homepage,
    "source_code_uri"       => "https://github.com/denmarkmeralpis/pilipinas/tree/main",
    "changelog_uri"         => "https://github.com/denmarkmeralpis/pilipinas/blob/main/CHANGELOG.md",
    "bug_tracker_uri"       => "https://github.com/denmarkmeralpis/pilipinas/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(test|spec|features)/}) || f.start_with?(".")
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # No runtime dependencies — pure Ruby + stdlib (psych ships with Ruby).

  spec.add_development_dependency "rake",            "~> 13.2"
  spec.add_development_dependency "rspec",           "~> 3.13"
  spec.add_development_dependency "shoulda-matchers","~> 6.0"
  spec.add_development_dependency "activerecord",    "~> 8.0"
  spec.add_development_dependency "sqlite3",         "~> 2.0"
  spec.add_development_dependency "simplecov",       "~> 0.22"
  spec.add_development_dependency "simplecov-console","~> 0.9"
  spec.add_development_dependency "rubocop",         "~> 1.65"
  spec.add_development_dependency "rubocop-rspec",   "~> 3.0"
end
