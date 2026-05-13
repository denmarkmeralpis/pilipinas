# frozen_string_literal: true

module Pilipinas
  module Db
    module Concerns
      # Shared ActiveRecord concern applied to every Pilipinas DB model.
      #
      # == What this solves
      #
      # The four pilipinas_* tables hold **static reference data** that never
      # changes after the initial seed.  Plain ActiveRecord has several sources
      # of unnecessary memory allocation for this workload:
      #
      # 1. **All columns are loaded by default**, including lft/rgt (nested-set
      #    hierarchy fields), longitude/latitude, income_class, etc. — most
      #    callers only ever need code + name.
      # 2. **STI type-column checking** — AR looks for a +type+ column on every
      #    query; these tables have none, so that check is pure overhead.
      # 3. **Dirty-tracking and callbacks** — pointless for read-only data.
      # 4. **Accidental writes** — a stray +save+ or +update+ on static data
      #    is almost always a bug; it should raise immediately.
      # 5. **Unbatched mass loads** — loading 42 k+ barangay rows in a single
      #    SQL statement creates a huge transient Array before AR can even
      #    instantiate objects.
      #
      # == Optimizations applied
      #
      # * +readonly?+ returns +true+ for persisted records when
      #   +enforce_readonly+ is +true+ (the default) — accidental
      #   +update!/save!/destroy+ on fetched rows raise
      #   +ActiveRecord::ReadOnlyRecord+; new records stay writable so the
      #   Loader and test fixtures can still call +create!+.
      # * +enforce_readonly+ class attribute: opt a subclass out of the
      #   read-only guard without touching production models — useful in test
      #   environments where factories need to write to pilipinas tables.
      # * +self.inheritance_column = :_sti_disabled+: removes STI type-column
      #   look-up from every query.
      # * +.lite+ scope: selects only +id+, +location_id+, +code+, +name+ —
      #   skips every spatial/hierarchy column, ~60 % less data per row for
      #   the barangays table (the largest one).
      # * +.by_code+ / +.by_name+ scopes: paired with +.lite+ these give
      #   the caller a single, readable one-liner that minimises allocations.
      # * Association lambdas on has_many restrict the SELECT to the five
      #   columns actually needed for traversal, so +region.provinces+,
      #   +province.cities+, and +city.barangays+ are all automatically lean.
      #
      # @example Lean look-up
      #   Pilipinas::Db::Region.lite.by_name("NCR")
      #   # SELECT id, location_id, code, name FROM pilipinas_regions
      #   # WHERE LOWER(name) = LOWER('NCR') LIMIT 1
      #
      # @example Traversal — no wasted columns loaded
      #   region.provinces   # SELECT id, location_id, parent_id, code, name …
      #   province.cities    # SELECT id, location_id, parent_id, code, name …
      #   city.barangays     # SELECT id, location_id, parent_id, code, name …
      #
      # @example Opting a subclass out of read-only enforcement (e.g. in tests)
      #   class Locations::Barangay < Pilipinas::Db::Barangay
      #     self.enforce_readonly = false
      #   end
      #
      module StaticRecord
        extend ActiveSupport::Concern

        # Columns loaded for associations and the +lite+ scope.
        # Excludes: lft, rgt, longitude, latitude, parent_id (for lite),
        #           income_class, urban_rural, district, timestamps.
        LITE_COLUMNS         = %i[id location_id code name].freeze
        TRAVERSAL_COLUMNS    = %i[id location_id parent_id code name].freeze

        included do
          # ── Disable STI ──────────────────────────────────────────────────
          # Removes the hidden "type" column check AR performs on every query.
          self.inheritance_column = :_sti_disabled

          # ── Read-only enforcement ─────────────────────────────────────────
          # Defaults to +true+.  Set to +false+ on a subclass (e.g. in a test
          # environment or for a model that legitimately needs write access)
          # without touching production behaviour:
          #
          #   class Locations::Barangay < Pilipinas::Db::Barangay
          #     self.enforce_readonly = false
          #   end
          class_attribute :enforce_readonly, instance_writer: false, default: true

          # ── Memory-efficient query scopes ─────────────────────────────────

          # Select only the four columns needed for display and look-up.
          # Usage: Model.lite.by_code("123")
          #
          # @return [ActiveRecord::Relation]
          scope :lite, -> { select(LITE_COLUMNS) }

          # Filter by exact code match (indexed column → fast).
          #
          # @param code [String, Integer]
          # @return [ActiveRecord::Relation]
          scope :by_code, ->(code) { where(code: code.to_s) }

          # Filter by case-insensitive name match (uses DB LOWER()).
          #
          # @param name [String]
          # @return [ActiveRecord::Relation]
          scope :by_name, ->(name) { where('LOWER(name) = LOWER(?)', name.to_s) }

          # Convenience: lite + single record by code.
          #
          # @param code [String, Integer]
          # @return [ActiveRecord::Base, nil]
          scope :find_lite_by_code, ->(code) { lite.by_code(code).first }

          # Convenience: lite + single record by name (case-insensitive).
          #
          # @param name [String]
          # @return [ActiveRecord::Base, nil]
          scope :find_lite_by_name, ->(name) { lite.by_name(name).first }
        end

        # Guards against accidental writes to static reference data.
        #
        # Returns +true+ (making the record read-only) when both conditions hold:
        # 1. The record is persisted (+new_record?+ is +false+).
        # 2. The class-level +enforce_readonly+ flag is +true+ (the default).
        #
        # New (unsaved) objects are always writable so the Loader and test
        # factories can call +create!+.  To allow writes on a subclass — for
        # example in a test environment — set:
        #
        #   self.enforce_readonly = false
        #
        # Overriding +readonly?+ is more efficient than an +after_initialize+
        # callback: it is only invoked when AR is about to perform a write
        # operation, so it adds zero overhead on read paths.
        #
        # @return [Boolean]
        def readonly?
          self.class.enforce_readonly && !new_record?
        end
      end
    end
  end
end
