# frozen_string_literal: true

require 'psych'
require 'json'
require 'pilipinas/version'
require 'pilipinas/cache'
require 'pilipinas/base'
require 'pilipinas/region'
require 'pilipinas/province'
require 'pilipinas/city'
require 'pilipinas/barangay'
require 'pilipinas/submunicipality'
require 'pilipinas/area'
require 'pilipinas/postal'
require 'pilipinas/loader'
# :nocov:
require 'pilipinas/railtie' if defined?(Rails)
# :nocov:

# Top-level namespace for the Pilipinas gem.
#
# Pilipinas is a read-only, file-backed directory of Philippine geographic
# divisions, including cities outside provincial administration.
#
# Current data is loaded from JSON files bundled inside the gem, cached in memory for
# the lifetime of the process, and exposed through a clean query API.
#
# == Quick start
#
#   require "pilipinas"
#
#   Pilipinas::Region.all                              # => [#<Region ...>, ...]
#   Pilipinas::Region.count                            # => 18
#
#   region = Pilipinas::Region.find_by(name: "REGION V (Bicol Region)")
#   region.provinces                                   # => [#<Province ...>, ...]
#
#   province = Pilipinas::Province.find_by(name: "CAMARINES SUR")
#   province.cities                                    # => [#<City ...>, ...]
#
#   city = Pilipinas::City.find_by(code: "0501724000")
#   city.barangays                                     # => [#<Barangay ...>, ...]
#
# == Database integration (optional – Rails only)
#
# The ActiveRecord integration uses a historical dataset, not current PSGC.
# For legacy ActiveRecord-backed models, run:
#
#   rails generate pilipinas:migration
#   rake pilipinas:load
#
module Pilipinas
  # Base error class for all Pilipinas exceptions.
  class Error < StandardError; end

  # Raised when an unsupported attribute is used in a +find_by_*+ call.
  class UnknownAttribute < Error; end

  class AmbiguousMatch < Error; end

  # Absolute path to the bundled +data/+ directory.
  # @api private
  DATA_DIR = File.expand_path('data', __dir__).freeze

  def self.metadata
    Cache.fetch('metadata') { JSON.parse(File.read(File.join(DATA_DIR, 'metadata.json')), freeze: true) }
  end

  def self.find_by_code(code)
    return nil if code.nil?

    [Region, Province, City, Barangay, Submunicipality, Area].each do |type|
      record = type.find_by_code(code)
      return record if record
    end
    nil
  end

  # A migration aid, never an automatic rewrite of saved addresses.
  def self.legacy_lookup(type:, code:)
    mapping = Cache.fetch('legacy_mapping') do
      JSON.parse(File.read(File.join(DATA_DIR, 'legacy_mapping.json')), freeze: true)
          .to_h { |row| [[row['type'], row['code']].freeze, row] }.freeze
    end
    mapping[[type.to_s, code.to_s]]
  end

  # ActiveRecord-backed models (opt-in; requires ActiveRecord to be loaded).
  module Db
    autoload :Region,   'pilipinas/db/region'
    autoload :Province, 'pilipinas/db/province'
    autoload :City,     'pilipinas/db/city'
    autoload :Barangay, 'pilipinas/db/barangay'
  end
end
