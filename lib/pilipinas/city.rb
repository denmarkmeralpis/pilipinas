# frozen_string_literal: true

module Pilipinas
  # Represents a city or municipality of the Philippines.
  #
  # Cities belong to a {Province} and contain one or more {Barangay} records.
  #
  # @example
  #   city = Pilipinas::City.find_by(name: "NAGA CITY")
  #   city.barangays  # => [#<Barangay ...>, ...]
  #
  class City < Base
    # Returns the barangays belonging to this city or municipality.
    #
    # Results are cached after the first call.
    #
    # @return [Array<Barangay>]
    def barangays
      Barangay.assoc_collection(code: code, dir: :cities)
    end

    class << self
      private

      # @return [String] absolute path to the cities YAML file
      def data_file
        File.join(Pilipinas::DATA_DIR, "cities.yml")
      end
    end
  end
end
