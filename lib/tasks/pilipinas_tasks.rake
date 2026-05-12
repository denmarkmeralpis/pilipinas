# frozen_string_literal: true

namespace :pilipinas do
  desc "Seed the pilipinas_* tables from the bundled YAML data files"
  task load: :environment do
    puts "Loading Philippine geographic data..."
    Pilipinas::Loader.run
    puts "Done."
  end
end
end
