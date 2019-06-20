require 'yaml' unless defined?(YAML)
require 'pilipinas/version'
require 'pilipinas/base'
require 'pilipinas/region'
require 'pilipinas/province'
require 'pilipinas/city'
require 'pilipinas/barangay'
require 'pilipinas/loader'
require 'pilipinas/railtie'
require 'fileutils'
require 'yaml_db'

module Pilipinas
  class Error < StandardError; end
  class UnknownAttribute < Error; end

  autoload :Region, 'pilipinas/db/region'
  autoload :Province, 'pilipinas/db/province'
  autoload :City, 'pilipinas/db/city'
  autoload :Barangay, 'pilipinas/db/barangay'
end
