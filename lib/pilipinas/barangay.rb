# frozen_string_literal: true

module Pilipinas
  class Barangay < Base
    def self.data_file = File.join(DATA_DIR, 'barangays.json')
    private_class_method :data_file
  end
end
