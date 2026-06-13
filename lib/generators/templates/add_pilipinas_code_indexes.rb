class AddPilipinasLocationIdIndexes < ActiveRecord::Migration<%= migration_version %>
  def change
    add_index :pilipinas_regions,   :location_id, unique: true, if_not_exists: true
    add_index :pilipinas_provinces, :location_id, unique: true, if_not_exists: true
    add_index :pilipinas_cities,    :location_id, unique: true, if_not_exists: true
    add_index :pilipinas_barangays, :location_id, unique: true, if_not_exists: true
  end
end
