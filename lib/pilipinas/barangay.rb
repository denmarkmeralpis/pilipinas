module Pilipinas
  class Barangay < Base
    class << self
      def load_data
        load_file(File.join(File.dirname(__FILE__), '..', 'data', 'barangays.yml'))
      end
    end
  end
end
