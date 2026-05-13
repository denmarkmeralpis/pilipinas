# frozen_string_literal: true

require_relative 'concerns/static_record'

module Pilipinas
  module Db
    # ActiveRecord model backed by the +pilipinas_barangays+ table.
    class Barangay < ActiveRecord::Base
      include Concerns::StaticRecord

      self.table_name = 'pilipinas_barangays'

      belongs_to :city,
                 -> { select(Concerns::StaticRecord::TRAVERSAL_COLUMNS) },
                 foreign_key: :parent_id,
                 primary_key: :location_id,
                 optional: true
    end
  end
end
