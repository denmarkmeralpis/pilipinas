# frozen_string_literal: true

module Pilipinas
  # Represents one of the 17 administrative regions of the Philippines.
  #
  # Each Region is the top-level geographic division and contains one or more
  # {Province} records.
  #
  # @example
  #   region = Pilipinas::Region.find_by(name: "REGION V (Bicol Region)")
  #   region.provinces  # => [#<Province ...>, ...]
  #
  class Region < Base
    # Returns the provinces belonging to this region.
    #
    # Results are cached after the first call.
    #
    # @return [Array<Province>]
    def provinces
      Province.assoc_collection(code: code, dir: :regions)
    end

    class << self
      private

      # @return [String] absolute path to the regions YAML file
      def data_file
        File.join(Pilipinas::DATA_DIR, "regions.yml")
      end
    end
  end
end
