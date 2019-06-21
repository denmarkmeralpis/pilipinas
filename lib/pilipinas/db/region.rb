module Pilipinas
  module Db
    class Region < ActiveRecord::Base
      self.table_name = 'pilipinas_regions'
      has_many :provinces, foreign_key: :parent_id, primary_key: :location_id
    end
  end
end
