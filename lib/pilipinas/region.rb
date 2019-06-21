module Pilipinas
  class Region < Base
    def provinces
      Pilipinas::Province.assoc_collection(code: code, dir: :regions)
    end

    class << self
      def load_data
        load_file(File.join(File.dirname(__FILE__), '..', 'data', 'regions.yml'))
      end
    end
  end
end
