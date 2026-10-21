# frozen_string_literal: true

module Pilipinas
  # PSGC non-province groupings: Special Geographic Area and City of Isabela.
  class Area < Base
    def cities = City.where(area_code: code)

    def self.data_file = File.join(DATA_DIR, 'areas.json')
    private_class_method :data_file
  end
end
