module Pilipinas
  module Db
    class Barangay <  ActiveRecord::Base
      self.table_name = 'pilipinas_barangays'
      belongs_to :city, foreign_key: :parent_id, primary_key: :location_id
    end
  end
end
