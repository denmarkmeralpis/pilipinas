# frozen_string_literal: true

require "rails/generators/base"
require "rails/generators/active_record"

module Pilipinas
  # Rails generator that creates the four pilipinas_* database tables.
  #
  # @example
  #   rails generate pilipinas:migration
  #
  class MigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path("..", __dir__)

    def generate_migration
      migration_template "templates/migration.rb", "db/migrate/create_pilipinas_locations.rb"
    end

    # Returns a timestamp-based migration number required by the Rails
    # migration DSL.
    #
    # @param _dir [String] unused (required by the interface)
    # @return [String]
    def self.next_migration_number(_dir)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end

    private

    # @return [String, nil] migration version bracket, e.g. "[8.0]"
    def migration_version
      "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
    end
  end
end
