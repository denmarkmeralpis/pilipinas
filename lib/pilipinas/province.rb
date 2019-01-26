module Pilipinas
   class Province < Base
      def cities
         Pilipinas::City.assoc_collection(code: code, dir: :provinces)
      end

      class << self
         def load_data
            load_file(File.join(File.dirname(__FILE__), '..', 'data', 'provinces.yml'))
         end
      end
   end
end
