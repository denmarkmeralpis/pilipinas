# frozen_string_literal: true

module Pilipinas
  class Region < Base
    def provinces = Province.where(region_code: code)
    # Includes every city/municipality, including those without a province.
    def cities = City.where(region_code: code)
    def cities_without_province = cities.select { |city| city.province_code.nil? }.freeze
    def areas = Area.where(region_code: code)

    def self.data_file = File.join(DATA_DIR, 'regions.json')
    private_class_method :data_file
  end
end
