require 'yaml' unless defined?(YAML)
require 'pilipinas/version'
require 'pilipinas/base'
require 'pilipinas/region'
require 'pilipinas/province'
require 'pilipinas/city'
require 'pilipinas/barangay'
require 'pilipinas/loader'
require 'pilipinas/railtie'

module Pilipinas
  class Error < StandardError; end
  class UnknownAttribute < Error; end
end
