module Pilipinas
  module Db
    class City < ActiveRecord::Base
      self.table_name = 'pilipinas_cities'
      has_many :barangays, foreign_key: :parent_id, primary_key: :location_id
      belongs_to :province, foreign_key: :parent_id, primary_key: :location_id
    end
  end
end
