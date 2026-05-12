# frozen_string_literal: true

module Pilipinas
  # Represents a barangay (the smallest administrative division) of the
  # Philippines.
  #
  # Barangays belong to a {City} or municipality.
  #
  # @example
  #   Pilipinas::Barangay.count  # => 42_027
  #   Pilipinas::Barangay.find_by(name: "Casay")
  #
  class Barangay < Base
    class << self
      private

      # @return [String] absolute path to the barangays YAML file
      def data_file
        File.join(Pilipinas::DATA_DIR, 'barangays.yml')
      end
    end
  end
end
