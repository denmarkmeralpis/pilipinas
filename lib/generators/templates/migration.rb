class CreateLocations < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :pilipinas_regions do |t|
      t.bigint  :location_id
      t.integer :lft
      t.integer :rgt
      t.string  :code
      t.string  :name
      t.string  :longitude
      t.string  :latitude
      t.timestamps default: Time.now
    end

    create_table :pilipinas_provinces do |t|
      t.bigint  :location_id
      t.bigint  :parent_id
      t.integer :lft
      t.integer :rgt
      t.string  :code
      t.string  :name
      t.string  :longitude
      t.string  :latitude
      t.timestamps default: Time.now
    end

    create_table :pilipinas_cities do |t|
      t.bigint  :location_id
      t.bigint  :parent_id
      t.integer :lft
      t.integer :rgt
      t.string  :code
      t.string  :name
      t.boolean :city, default: false
      t.string  :income_class
      t.string  :urban_rural
      t.string  :district
      t.string  :longitude
      t.string  :latitude
      t.boolean :capital, default: false
      t.timestamps default: Time.now
    end

    create_table :pilipinas_barangays do |t|
      t.bigint  :location_id
      t.bigint  :parent_id
      t.integer :lft
      t.integer :rgt
      t.string  :code
      t.string  :name
      t.string  :urban_rural
      t.timestamps default: Time.now
    end

    add_index :pilipinas_regions, :location_id, unique: true
    add_index :pilipinas_regions, :code
    add_index :pilipinas_regions, :rgt

    add_index :pilipinas_provinces, :location_id, unique: true
    add_index :pilipinas_provinces, :code
    add_index :pilipinas_provinces, :parent_id
    add_index :pilipinas_provinces, :rgt

    add_index :pilipinas_cities, :location_id, unique: true
    add_index :pilipinas_cities, :code
    add_index :pilipinas_cities, :parent_id
    add_index :pilipinas_cities, :rgt

    add_index :pilipinas_barangays, :location_id, unique: true
    add_index :pilipinas_barangays, :code
    add_index :pilipinas_barangays, :parent_id
    add_index :pilipinas_barangays, :rgt
  end
end
