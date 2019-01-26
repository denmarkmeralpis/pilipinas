module Pilipinas
   class City < Base
      def barangays
         Pilipinas::Barangay.assoc_collection(code: code, dir: :cities)
      end

      class << self
         def load_data
            load_file(File.join(File.dirname(__FILE__), '..', 'data', 'cities.yml'))
         end
      end
   end
end