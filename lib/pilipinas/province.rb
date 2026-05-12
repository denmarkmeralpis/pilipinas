# frozen_string_literal: true

module Pilipinas
  # Represents a province (or province-equivalent district) of the Philippines.
  #
  # Provinces belong to a {Region} and contain one or more {City} records.
  #
  # @example
  #   province = Pilipinas::Province.find_by(name: "CAMARINES SUR")
  #   province.cities  # => [#<City ...>, ...]
  #
  class Province < Base
    # Returns the cities/municipalities belonging to this province.
    #
    # Results are cached after the first call.
    #
    # @return [Array<City>]
    def cities
      City.assoc_collection(code: code, dir: :provinces)
    end

    class << self
      private

      # @return [String] absolute path to the provinces YAML file
      def data_file
        File.join(Pilipinas::DATA_DIR, 'provinces.yml')
      end
    end
  end
end
