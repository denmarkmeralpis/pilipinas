class CreateLocations < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :pilipinas_locations do |t|
      t.bigint  :parent_id
      t.integer :lft
      t.integer :rgt
      t.string  :location_type
      t.string  :code
      t.string  :name
      t.boolean :city, default: false
      t.string  :income_class
      t.string  :urban_rural
      t.string  :district
      t.string  :postcode
      t.string  :longitude
      t.string  :latitude
      t.bigint  :location_id
      t.timestamps default: Time.now
    end

    add_index :locations, :parent_id
    add_index :locations, :postcode
    add_index :locations, [:name, :location_type, :postcode]
  end
end
