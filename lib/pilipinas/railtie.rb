# frozen_string_literal: true

require "rails"
require "pilipinas"

module Pilipinas
  # Integrates Pilipinas with Ruby on Rails.
  #
  # Automatically loaded when +pilipinas+ is required inside a Rails
  # application.  Registers the bundled Rake tasks so that
  # +rake pilipinas:load+ is available in any host app.
  class Railtie < Rails::Railtie
    railtie_name :pilipinas

    rake_tasks do
      tasks_path = File.expand_path("../tasks", __dir__)
      Dir.glob("#{tasks_path}/**/*.rake").each { |f| load f }
    end
  end
end
