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
end
