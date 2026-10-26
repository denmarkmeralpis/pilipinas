# frozen_string_literal: true

module Pilipinas
  module Loader
    # Deletes rows from a pilipinas_* table that are not part of the bundled
    # data set:
    #
    # * compact rows seeded by older loader versions, which have only +code+
    #   and +name+ and a NULL +location_id+;
    # * locations dropped from a newer PSGC snapshot.  Upserting never touches
    #   these, and left in place they would still match +parent_id+
    #   associations and nested-set +lft+/+rgt+ range queries.
    #
    # The loader runs this before upserting so a +code+ freed by a removed
    # location can be reused by a new one without tripping the unique +code+
    # index.
    #
    # @api private
    module StaleRows
      class << self
        # Stale ids are found in Ruby and deleted in {Loader::BATCH_SIZE}
        # slices so no single statement carries a ~42 k-element +NOT IN+ list.
        #
        # @param model          [Class] ActiveRecord model class
        # @param records        [Array<Array>] full location dump rows
        # @param column_indexes [Hash] source column names mapped to row indexes
        # @param type           [String] source STI type whose rows +model+ holds
        # @return [Integer] number of rows deleted
        # @raise [Pilipinas::Error] when an application foreign key still
        #   references a stale row
        def delete(model, records, column_indexes, type)
          current_ids = location_ids(records, column_indexes, type)
          stale_ids = model.where.not(location_id: nil).pluck(:location_id).reject { |id| current_ids.include?(id) }

          model.where(location_id: nil).delete_all +
            stale_ids.each_slice(BATCH_SIZE).sum { |ids| model.where(location_id: ids).delete_all }
        rescue ActiveRecord::InvalidForeignKey
          raise Pilipinas::Error,
                "pilipinas:load could not delete rows from #{model.table_name} that are no longer in " \
                'the bundled PSGC data, because rows in your application still reference them through ' \
                'a foreign key. Point those references at current locations or remove them, then ' \
                're-run `rake pilipinas:load`.'
        end

        private

        # @return [Set<Integer>] location ids of every dump row of +type+
        def location_ids(records, column_indexes, type)
          type_index, location_id_index = column_indexes.fetch_values('type', 'location_id')

          records.each_with_object(Set.new) do |record, ids|
            ids << record[location_id_index] if record[type_index] == type
          end
        end
      end
    end
  end
end
