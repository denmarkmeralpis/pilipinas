# frozen_string_literal: true

require_relative "concerns/static_record"

module Pilipinas
  module Db
    # ActiveRecord model backed by the +pilipinas_provinces+ table.
    class Province < ActiveRecord::Base
      include Concerns::StaticRecord

      self.table_name = "pilipinas_provinces"

      belongs_to :region,
                 -> { select(Concerns::StaticRecord::TRAVERSAL_COLUMNS) },
                 foreign_key: :parent_id,
                 primary_key: :location_id,
                 optional:    true

      has_many   :cities,
                 -> { select(Concerns::StaticRecord::TRAVERSAL_COLUMNS) },
                 foreign_key: :parent_id,
                 primary_key: :location_id
    end
  end
end


