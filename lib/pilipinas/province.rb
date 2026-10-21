# frozen_string_literal: true

module Pilipinas
  class Province < Base
    # Administrative membership. ICC/HUC cities are reachable via Region#cities.
    def cities = City.where(province_code: code)

    def self.data_file = File.join(DATA_DIR, 'provinces.json')
    private_class_method :data_file
  end
end
