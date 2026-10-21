# frozen_string_literal: true

# Run outside Bundler after installing the built gem (see docs/VALIDATION.md).
gem 'pilipinas', '= 2.0.0'
require 'pilipinas'

raise 'Wrong Ruby' unless RUBY_VERSION == '3.4.11'
raise 'Unexpected runtime dependencies' unless Gem.loaded_specs.fetch('pilipinas').runtime_dependencies.empty?
raise 'Unexpected database/network client' if defined?(ActiveRecord) || defined?(Net::HTTP)

counts = [Pilipinas::Region.count, Pilipinas::Province.count, Pilipinas::City.count, Pilipinas::Barangay.count]
raise "Wrong counts: #{counts}" unless counts == [18, 82, 1642, 42_010]

codes = Pilipinas::Region.all.flat_map(&:cities).flat_map(&:barangays).map(&:code)
raise 'Incomplete traversal' unless codes.size == 42_010 && codes.uniq.size == codes.size
raise 'Wrong correction' unless Pilipinas::Barangay.find_by_code('1001322005').name == 'Lambagan'
raise 'Wrong ZIP' unless Pilipinas::Postal.lookup(locality: 'Pandacan', province: 'Metro Manila').suggestion == '1011'
raise 'Lost postal ambiguity' unless Pilipinas::Postal.lookup(locality: 'Santa Maria').status == :ambiguous
raise 'Guessed ZIP' unless Pilipinas::Postal.lookup(locality: 'Makati', province: 'Metro Manila').suggestion.nil?
raise 'Missing rejection' unless Pilipinas::Postal.lookup(locality: 'Cajidiocan').rejected_rows.size == 1
raise 'Lost provenance' unless Pilipinas.metadata.dig('psgc', 'snapshot_date') == '2026-09-30'
raise 'Lost legacy mapping' unless Pilipinas.legacy_lookup(type: :cities, code: '18817')['status'] == 'matched'

puts "Installed gem smoke check passed on Ruby #{RUBY_VERSION}: #{Gem.loaded_specs.fetch('pilipinas').full_gem_path}"
