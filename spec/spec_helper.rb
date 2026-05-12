# frozen_string_literal: true

require "bundler/setup"
require "simplecov"
require "simplecov-console"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::Console]
)
SimpleCov.start do
  add_filter "/spec/"
  enable_coverage :branch
end

require "pilipinas"
require "shoulda-matchers"
require "active_record"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Ensure the in-process data cache is clean between examples.
  config.before { Pilipinas::Cache.clear }
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :active_record
    with.library :active_model
  end
end

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

load File.join(__dir__, "schema.rb")
