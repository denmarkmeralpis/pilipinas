namespace :pilipinas do
  desc 'Load data to a table named pilipinas_locations'
  task load_data: :environment do
    Pilipinas::Loader.run
  end
end
