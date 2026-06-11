# frozen_string_literal: true

require 'rails/generators/base'
require 'rails/generators/active_record'

module Pilipinas
  # Rails generator that adds unique indexes on the +code+ column to all four
  # pilipinas_* tables.
  #
  # Run this if your database was created with an older version of the gem
  # that did not include these indexes, and +rake pilipinas:load+ raises:
  #
  #   ArgumentError: No unique index found for code
  #
  # @example
  #   rails generate pilipinas:code_indexes
  #   rails db:migrate
  #
  class CodeIndexesGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('..', __dir__)

    def generate_migration
      migration_template 'templates/add_pilipinas_code_indexes.rb',
                         'db/migrate/add_pilipinas_code_indexes.rb'
    end

    # @param _dir [String] unused (required by the interface)
    # @return [String]
    def self.next_migration_number(_dir)
      Time.now.utc.strftime('%Y%m%d%H%M%S')
    end

    private

    # @return [String] migration version bracket, e.g. "[8.0]"
    def migration_version
      "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
    end
  end
end
