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
  # * **Memory-efficient** — rows are inserted in batches of {BATCH_SIZE}
  #   (default 500) so the process never holds a 42 k-row Array in memory.
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

    class << self
      # Seed all four geographic tables inside a single transaction.
      #
      # @return [void]
      def run
        ActiveRecord::Base.transaction do
          seed(Db::Region,   'regions.yml')
          seed(Db::Province, 'provinces.yml')
          seed(Db::City,     'cities.yml')
          seed(Db::Barangay, 'barangays.yml')
        end
      end

      private

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
                  "pilipinas:load requires a unique index on the `code` column, " \
                  "which is missing from #{model.table_name}. " \
                  "Your database was likely created with an older version of the gem. " \
                  "Run the following to add the missing indexes and retry:\n\n" \
                  "  rails generate pilipinas:code_indexes\n" \
                  "  rails db:migrate\n"
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
