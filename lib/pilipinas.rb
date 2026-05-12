# frozen_string_literal: true

require "psych"
require "pilipinas/version"
require "pilipinas/cache"
require "pilipinas/base"
require "pilipinas/region"
require "pilipinas/province"
require "pilipinas/city"
require "pilipinas/barangay"
require "pilipinas/loader"
require "pilipinas/railtie" if defined?(Rails)

# Top-level namespace for the Pilipinas gem.
#
# Pilipinas is a read-only, file-backed directory of Philippine geographic
# divisions: Regions → Provinces → Cities/Municipalities → Barangays.
#
# Data is loaded from YAML files bundled inside the gem, cached in memory for
# the lifetime of the process, and exposed through a clean query API.
#
# == Quick start
#
#   require "pilipinas"
#
#   Pilipinas::Region.all                              # => [#<Region ...>, ...]
#   Pilipinas::Region.count                            # => 17
#
#   region = Pilipinas::Region.find_by(name: "REGION V (Bicol Region)")
#   region.provinces                                   # => [#<Province ...>, ...]
#
#   province = Pilipinas::Province.find_by(name: "CAMARINES SUR")
#   province.cities                                    # => [#<City ...>, ...]
#
#   city = Pilipinas::City.find_by(name: "NAGA CITY")
#   city.barangays                                     # => [#<Barangay ...>, ...]
#
# == Database integration (optional – Rails only)
#
# For ActiveRecord-backed models, run:
#
#   rails generate pilipinas:migration
#   rake pilipinas:load
#
module Pilipinas
  # Base error class for all Pilipinas exceptions.
  class Error < StandardError; end

  # Raised when an unsupported attribute is used in a +find_by_*+ call.
  class UnknownAttribute < Error; end

  # Absolute path to the bundled +data/+ directory.
  # @api private
  DATA_DIR = File.expand_path("data", __dir__).freeze

  # ActiveRecord-backed models (opt-in; requires ActiveRecord to be loaded).
  module Db
    autoload :Region,   "pilipinas/db/region"
    autoload :Province, "pilipinas/db/province"
    autoload :City,     "pilipinas/db/city"
    autoload :Barangay, "pilipinas/db/barangay"
  end
end
