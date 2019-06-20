module Pilipinas
  module Db
    class Province < ActiveRecord::Base
      self.table_name = 'pilipinas_provinces'
      belongs_to :region, foreign_key: :parent_id, primary_key: :location_id
      has_many :cities, foreign_key: :parent_id, primary_key: :location_id
    end
  end
end
