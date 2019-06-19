class CreateLocations < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :pilipinas_locations do |t|
      t.bigint  :parent_id
      t.integer :lft
      t.integer :rgt
      t.string  :type
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

    add_index :pilipinas_locations, :location_id
    add_index :pilipinas_locations, :code
    add_index :pilipinas_locations, :parent_id
    add_index :pilipinas_locations, :postcode
    add_index :pilipinas_locations, [:name, :location_type, :postcode], name: 'index_pilipinas_locations_on_name_type_postcode'
  end
end
