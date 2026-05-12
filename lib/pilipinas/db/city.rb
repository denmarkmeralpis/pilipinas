# frozen_string_literal: true

require_relative "concerns/static_record"

module Pilipinas
  module Db
    # ActiveRecord model backed by the +pilipinas_cities+ table.
    class City < ActiveRecord::Base
      include Concerns::StaticRecord

      self.table_name = "pilipinas_cities"

      belongs_to :province,
                 -> { select(Concerns::StaticRecord::TRAVERSAL_COLUMNS) },
                 foreign_key: :parent_id,
                 primary_key: :location_id,
                 optional:    true

      has_many   :barangays,
                 -> { select(Concerns::StaticRecord::TRAVERSAL_COLUMNS) },
                 foreign_key: :parent_id,
                 primary_key: :location_id
    end
  end
end


