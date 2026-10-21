# frozen_string_literal: true

module Pilipinas
  # Both cities (level City) and municipalities (level Mun).
  class City < Base
    # Manila's barangays are included across all its sub-municipal districts.
    def barangays = Barangay.where(city_code: code)
    def submunicipalities = Submunicipality.where(city_code: code)

    def self.data_file = File.join(DATA_DIR, 'cities.json')
    private_class_method :data_file
  end
end
