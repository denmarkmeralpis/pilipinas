namespace :pilipinas do
  desc 'Load data to a table named pilipinas_locations'
  task load: :environment do
    Pilipinas::Loader.run
  end
end
