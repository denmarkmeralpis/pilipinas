# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pilipinas::Region do
  subject(:klass) { described_class }

  describe ".all" do
    it "returns an Array" do
      expect(klass.all).to be_an(Array)
    end

    it "returns 17 regions" do
      expect(klass.all.count).to eq(17)
    end

    it "returns a frozen Array" do
      expect(klass.all).to be_frozen
    end
  end

  describe "#provinces" do
    it "returns an Array of Province objects" do
      expect(klass.first.provinces).to be_an(Array)
    end

    it "returns frozen Province instances" do
      expect(klass.first.provinces.first).to be_frozen
    end
  end

  describe ".find_by_code" do
    it "finds a region by code" do
      expect(klass.find_by_code("17744")).to be_a(described_class)
    end

    it "is case-insensitive" do
      expect(klass.find_by_code("17744")).to eq(klass.find_by_code("17744"))
    end

    it "returns nil for an unknown code" do
      expect(klass.find_by_code("999999")).to be_nil
    end
  end

  describe ".find_by_name" do
    it "finds a region by name" do
      expect(klass.find_by_name("REGION V (Bicol Region)")).to be_a(described_class)
    end

    it "is case-insensitive" do
      lower  = klass.find_by_name("region v (bicol region)")
      upper  = klass.find_by_name("REGION V (Bicol Region)")
      expect(lower).to eq(upper)
    end
  end

  describe ".find_by_something (unsupported attribute)" do
    it "raises Pilipinas::UnknownAttribute" do
      expect { klass.find_by_something }.to raise_error(Pilipinas::UnknownAttribute)
    end
  end
end

