# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pilipinas::City do
  subject(:klass) { described_class }

  describe ".all" do
    it "returns an Array" do
      expect(klass.all).to be_an(Array)
    end

    it "returns 1648 cities/municipalities" do
      expect(klass.all.count).to eq(1648)
    end
  end

  describe "#barangays" do
    it "returns an Array of Barangay objects" do
      expect(klass.first.barangays).to be_an(Array)
    end
  end

  describe ".find_by_code" do
    it "finds a city by code" do
      expect(klass.find_by_code("18817")).to be_a(described_class)
    end

    it "returns nil for an unknown code" do
      expect(klass.find_by_code("999999")).to be_nil
    end
  end

  describe ".find_by_name" do
    it "finds a city by name" do
      expect(klass.find_by_name("NAGA CITY")).to be_a(described_class)
    end

    it "is case-insensitive" do
      lower = klass.find_by_name("naga city")
      upper = klass.find_by_name("NAGA CITY")
      expect(lower).to eq(upper)
    end
  end

  describe ".find_by_something (unsupported attribute)" do
    it "raises Pilipinas::UnknownAttribute" do
      expect { klass.find_by_something }.to raise_error(Pilipinas::UnknownAttribute)
    end
  end
end

