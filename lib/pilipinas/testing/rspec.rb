# frozen_string_literal: true

require 'pilipinas'

# Pilipinas::Testing::RSpec
#
# Optional RSpec helper that disables the read-only guard on all Pilipinas DB
# models for the duration of the test suite.  Require this file once (e.g. in
# +rails_helper.rb+ or +spec/support/pilipinas.rb+) and FactoryBot factories,
# fixtures, or any spec that needs to write to pilipinas_* tables will work
# without stubbing or subclass overrides.
#
# == Usage
#
#   # spec/rails_helper.rb  (or spec/support/pilipinas.rb)
#   require 'pilipinas/testing/rspec'
#
# == What it does
#
# Calls +enforce_readonly = false+ on every Pilipinas DB model inside a
# +before(:suite)+ hook so the flag is set once, before any example runs.
# The models remain writable for the entire test process, which is the correct
# behaviour for a test environment where factories seed the pilipinas_* tables.
#
# If you need write access only in a specific context, set the flag manually
# with an +around+ hook instead of requiring this file globally.
#
# == Models affected
#
# * Pilipinas::Db::Region
# * Pilipinas::Db::Province
# * Pilipinas::Db::City
# * Pilipinas::Db::Barangay

require 'rspec/core'

RSpec.configure do |config|
  config.before(:suite) do
    [
      Pilipinas::Db::Region,
      Pilipinas::Db::Province,
      Pilipinas::Db::City,
      Pilipinas::Db::Barangay
    ].each { |model| model.enforce_readonly = false }
  end
end
