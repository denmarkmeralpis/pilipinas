require 'rails/generators/base'
require 'rails/generators/active_record'

module Pilipinas
  class Upgrade020Generator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../', __dir__)

    def generate_migration
      generate_block_migration
    end

    def self.next_migration_number(_dir)
      Time.now.utc.strftime('%Y%m%d%H%M%S')
    end

    private

    def generate_block_migration
      migration_template 'templates/upgrade020.rb', 'db/migrate/upgrade_locations020.rb'
    end

    def migration_version
      formatted_version if ActiveRecord::VERSION::MAJOR.to_i >= 5
    end

    def formatted_version
      "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
    end
  end
end
