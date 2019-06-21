require 'yaml' unless defined?(YAML)
require 'pilipinas/version'
require 'pilipinas/base'
require 'pilipinas/region'
require 'pilipinas/province'
require 'pilipinas/city'
require 'pilipinas/barangay'

module Pilipinas
  class Error < StandardError; end
  class UnknownAttribute < Error; end
end
