# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pilipinas::Province do
  subject(:klass) { described_class }

  describe ".all" do
    it "returns an Array" do
      expect(klass.all).to be_an(Array)
    end

    it "returns 86 provinces" do
      expect(klass.all.count).to eq(86)
    end
  end

  describe "#cities" do
    it "returns an Array of City objects" do
      expect(klass.first.cities).to be_an(Array)
    end
  end

  describe ".find_by_code" do
    it "finds a province by code" do
      expect(klass.find_by_code("2")).to be_a(described_class)
    end

    it "returns nil for an unknown code" do
      expect(klass.find_by_code("999999")).to be_nil
    end
  end

  describe ".find_by_name" do
    it "finds a province by name" do
      expect(klass.find_by_name("CAMARINES SUR")).to be_a(described_class)
    end

    it "is case-insensitive" do
      lower = klass.find_by_name("camarines sur")
      upper = klass.find_by_name("CAMARINES SUR")
      expect(lower).to eq(upper)
    end
  end

  describe ".find_by_something (unsupported attribute)" do
    it "raises Pilipinas::UnknownAttribute" do
      expect { klass.find_by_something }.to raise_error(Pilipinas::UnknownAttribute)
    end
  end
end

