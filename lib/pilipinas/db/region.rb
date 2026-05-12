# frozen_string_literal: true

require_relative "concerns/static_record"

module Pilipinas
  module Db
    # ActiveRecord model backed by the +pilipinas_regions+ table.
    class Region < ActiveRecord::Base
      include Concerns::StaticRecord

      self.table_name = "pilipinas_regions"

      # Traversal scope restricts SELECT to the five columns needed for
      # navigation, avoiding lft/rgt/longitude/latitude overhead.
      has_many :provinces,
               -> { select(Concerns::StaticRecord::TRAVERSAL_COLUMNS) },
               foreign_key: :parent_id,
               primary_key: :location_id
    end
  end
end


