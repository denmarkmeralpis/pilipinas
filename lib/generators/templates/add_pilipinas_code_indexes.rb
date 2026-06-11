class AddPilipinasCodeIndexes < ActiveRecord::Migration<%= migration_version %>
  def change
    add_index :pilipinas_regions,   :code, unique: true, if_not_exists: true
    add_index :pilipinas_provinces, :code, unique: true, if_not_exists: true
    add_index :pilipinas_cities,    :code, unique: true, if_not_exists: true
    add_index :pilipinas_barangays, :code, unique: true, if_not_exists: true
  end
end
