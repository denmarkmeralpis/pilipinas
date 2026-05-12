# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pilipinas do
  it "has a version number" do
    expect(Pilipinas::VERSION).not_to be_nil
  end

  it "exposes a DATA_DIR constant pointing to an existing directory" do
    expect(File.directory?(Pilipinas::DATA_DIR)).to be true
  end

  it "defines expected error classes" do
    expect(Pilipinas::Error).to be < StandardError
    expect(Pilipinas::UnknownAttribute).to be < Pilipinas::Error
  end

  describe "railtie conditional require" do
    it "requires pilipinas/railtie when Rails is defined" do
      pilipinas_rb  = $LOADED_FEATURES.find { |f| f.end_with?("lib/pilipinas.rb") }
      railtie_rb    = $LOADED_FEATURES.find { |f| f.end_with?("pilipinas/railtie.rb") }
      prior_verbose = $VERBOSE

      stub_const("Rails", Module.new)
      $LOADED_FEATURES.delete(pilipinas_rb) if pilipinas_rb
      $LOADED_FEATURES.delete(railtie_rb)   if railtie_rb
      $VERBOSE = nil
      load pilipinas_rb
      $VERBOSE = prior_verbose

      expect(defined?(Pilipinas::Railtie)).to eq("constant")

      # Trigger the rake_tasks block to cover railtie.rb lines 16-17.
      require "rake"
      Pilipinas::Railtie.rake_tasks.each(&:call)
    ensure
      $LOADED_FEATURES << pilipinas_rb if pilipinas_rb && !$LOADED_FEATURES.include?(pilipinas_rb)
    end
  end
end
