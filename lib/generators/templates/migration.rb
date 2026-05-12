class CreatePilipinasLocations < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :pilipinas_regions do |t|
      t.bigint  :location_id
      t.integer :lft
      t.integer :rgt
      t.string  :code,      null: false
      t.string  :name,      null: false
      t.string  :longitude
      t.string  :latitude
      t.timestamps null: false
    end

    create_table :pilipinas_provinces do |t|
      t.bigint  :location_id
      t.bigint  :parent_id
      t.integer :lft
      t.integer :rgt
      t.string  :code,      null: false
      t.string  :name,      null: false
      t.string  :longitude
      t.string  :latitude
      t.timestamps null: false
    end

    create_table :pilipinas_cities do |t|
      t.bigint  :location_id
      t.bigint  :parent_id
      t.integer :lft
      t.integer :rgt
      t.string  :code,         null: false
      t.string  :name,         null: false
      t.boolean :city,         default: false, null: false
      t.string  :income_class
      t.string  :urban_rural
      t.string  :district
      t.string  :longitude
      t.string  :latitude
      t.timestamps null: false
    end

    create_table :pilipinas_barangays do |t|
      t.bigint  :location_id
      t.bigint  :parent_id
      t.integer :lft
      t.integer :rgt
      t.string  :code,        null: false
      t.string  :name,        null: false
      t.string  :urban_rural
      t.timestamps null: false
    end

    add_index :pilipinas_regions,   :location_id, unique: true
    add_index :pilipinas_regions,   :code,        unique: true
    # Composite (lft, rgt) supports nested-set descendant range queries:
    # WHERE lft >= X AND rgt <= Y  — a single rgt index cannot satisfy this.
    add_index :pilipinas_regions,   %i[lft rgt], name: 'idx_pilipinas_regions_lft_rgt'
    # Functional index lets LOWER(name) = LOWER(?) use the index (PostgreSQL).
    add_index :pilipinas_regions,   'LOWER(name)', name: 'idx_pilipinas_regions_lower_name'

    add_index :pilipinas_provinces, :location_id, unique: true
    add_index :pilipinas_provinces, :code,        unique: true
    add_index :pilipinas_provinces, :parent_id
    add_index :pilipinas_provinces, %i[lft rgt], name: 'idx_pilipinas_provinces_lft_rgt'
    add_index :pilipinas_provinces, 'LOWER(name)', name: 'idx_pilipinas_provinces_lower_name'

    add_index :pilipinas_cities,    :location_id, unique: true
    add_index :pilipinas_cities,    :code,        unique: true
    add_index :pilipinas_cities,    :parent_id
    add_index :pilipinas_cities,    %i[lft rgt], name: 'idx_pilipinas_cities_lft_rgt'
    add_index :pilipinas_cities,    'LOWER(name)', name: 'idx_pilipinas_cities_lower_name'

    add_index :pilipinas_barangays, :location_id, unique: true
    add_index :pilipinas_barangays, :code,        unique: true
    add_index :pilipinas_barangays, :parent_id
    add_index :pilipinas_barangays, %i[lft rgt], name: 'idx_pilipinas_barangays_lft_rgt'
    add_index :pilipinas_barangays, 'LOWER(name)', name: 'idx_pilipinas_barangays_lower_name'
  end
end

