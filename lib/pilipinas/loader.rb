# frozen_string_literal: true

module Pilipinas
  # Seeds the application database with Philippine geographic data.
  #
  # Reads directly from the gem's bundled YAML files and writes to the four
  # pilipinas_* tables via ActiveRecord.  The loader is designed to be:
  #
  # * **Idempotent** — uses +upsert_all+ (Rails 6.1+) so re-running the Rake
  #   task is safe.  Falls back to +insert_all+ (Rails 6.0) or individual
  #   +create!+ calls on older versions.
  # * **Memory-aware** — rows are transformed and inserted in batches of
  #   {BATCH_SIZE} (default 500) so the process never holds a full
  #   ActiveRecord insert payload in memory.
  # * **Atomic** — all four tables are seeded inside a single transaction; a
  #   failure rolls back everything, leaving no partial data.
  #
  # @example
  #   Pilipinas::Loader.run
  #
  module Loader
    # Number of rows inserted per SQL statement.
    # 500 balances SQL statement size against the number of round-trips.
    BATCH_SIZE = 500
    FULL_DATA_FILE = 'pilipinas_data.yml'
    LOCATION_TABLE = 'pilipinas_locations'

    FULL_DATA_SEEDS = [
      ['Region', 'Locations::Region', %w[location_id lft rgt code name longitude latitude]],
      ['Province', 'Locations::Province', %w[location_id parent_id lft rgt code name longitude latitude]],
      [
        'City',
        'Locations::Town',
        %w[location_id parent_id lft rgt code name city income_class urban_rural district longitude latitude]
      ],
      ['Barangay', 'Locations::Barangay', %w[location_id parent_id lft rgt code name urban_rural]]
    ].freeze
    private_constant :FULL_DATA_FILE, :LOCATION_TABLE, :FULL_DATA_SEEDS

    class << self
      # Seed all four geographic tables inside a single transaction.
      #
      # @return [void]
      def run
        column_indexes, records = full_location_table

        ActiveRecord::Base.transaction do
          FULL_DATA_SEEDS.each do |model_name, type, attributes|
            model = Db.const_get(model_name)
            seed_full_data(model, records, column_indexes, type, attributes)
          end
        end
      end

      private

      # Load the full Rails fixture-style location dump bundled with the gem.
      #
      # The older per-table YAML files only contain +code+ and +name+ for the
      # file-backed API.  Database seeding needs the complete dump so lft/rgt,
      # parent links, coordinates, and classification fields are populated.
      #
      # @return [Array(Hash, Array<Array>)]
      def full_location_table
        data = Psych.load_file(File.join(DATA_DIR, FULL_DATA_FILE)) || {}
        table = data.fetch(LOCATION_TABLE)
        columns = table.fetch('columns').map(&:to_s)

        [columns.each_with_index.to_h, table.fetch('records')]
      end

      # Insert or update rows for one split table from the full location dump.
      #
      # @param model          [Class] ActiveRecord model class
      # @param records        [Array<Array>] full location dump rows
      # @param column_indexes [Hash] source column names mapped to row indexes
      # @param type           [String] source STI type to select
      # @param attributes     [Array<String>] destination table attributes
      # @return [void]
      def seed_full_data(model, records, column_indexes, type, attributes)
        type_index = column_indexes.fetch('type')
        attribute_indexes = attributes.to_h { |attribute| [attribute, column_indexes.fetch(attribute)] }
        now = timestamp
        batch = []

        records.each do |record|
          next unless record[type_index] == type

          batch << full_data_attributes(record, attribute_indexes, now)

          next if batch.size < BATCH_SIZE

          bulk_insert(model, batch)
          batch = []
        end

        bulk_insert(model, batch) unless batch.empty?
      end

      # @param record            [Array] full location dump row
      # @param attribute_indexes [Hash] destination attributes mapped to row indexes
      # @param now               [Time] timestamp shared by the current table seed
      # @return [Hash]
      def full_data_attributes(record, attribute_indexes, now)
        attribute_indexes.to_h { |attribute, index| [attribute, record[index]] }
                         .merge('created_at' => now, 'updated_at' => now)
      end

      # Insert or update rows for one table from a YAML file.
      #
      # @param model    [Class]  ActiveRecord model class
      # @param filename [String] YAML filename relative to {DATA_DIR}
      # @return [void]
      def seed(model, filename)
        records = Psych.load_file(File.join(DATA_DIR, filename)) || []
        return if records.empty?

        now = timestamp

        # Slice the raw YAML Array first so we never hold a fully-transformed
        # copy of all rows in memory at once.  For barangays (~42 k rows) this
        # halves peak transient allocation compared to map-then-slice.
        records.each_slice(BATCH_SIZE) do |slice|
          batch = slice.map { |r| r.transform_keys(&:to_s).merge('created_at' => now, 'updated_at' => now) }
          bulk_insert(model, batch)
        end
      end

      # Perform the most capable bulk-insert available for this AR version.
      #
      # +upsert_all+ (Rails 6.1+) is idempotent — it updates existing rows
      # matched by the unique index on +code+, which is present in every YAML
      # record.  Using +code+ (not +location_id+) as the conflict column is
      # essential because +location_id+ is nullable and NULL != NULL in SQL —
      # a unique index on a nullable column cannot reliably detect conflicts.
      #
      # +insert_all+ (Rails 6.0) silently skips conflicts.
      # Legacy path: individual +create!+ calls (raises on conflict).
      #
      # @param model [Class]
      # @param batch [Array<Hash>]
      # @return [void]
      def bulk_insert(model, batch)
        if model.respond_to?(:upsert_all)
          begin
            model.upsert_all(batch, unique_by: :code)
          rescue ArgumentError
            raise Pilipinas::Error,
                  'pilipinas:load requires a unique index on the `code` column, ' \
                  "which is missing from #{model.table_name}. " \
                  'Your database was likely created with an older version of the gem. ' \
                  "Run the following to add the missing indexes and retry:\n\n  " \
                  "rails generate pilipinas:code_indexes\n  " \
                  "rails db:migrate\n"
          end
        elsif model.respond_to?(:insert_all)
          model.insert_all(batch)
        else
          batch.each { |attrs| model.unscoped.create!(attrs) }
        end
      end

      # @return [Time] current UTC time, compatible with or without ActiveSupport
      def timestamp
        defined?(Time.current) ? Time.current : Time.now.utc
      end
    end
  end
end
