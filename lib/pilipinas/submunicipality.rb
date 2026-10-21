# frozen_string_literal: true

module Pilipinas
  # Official Manila municipal districts; not counted as municipalities.
  class Submunicipality < Base
    def barangays = Barangay.where(submunicipality_code: code)

    def self.data_file = File.join(DATA_DIR, 'submunicipalities.json')
    private_class_method :data_file
  end
end
