# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pilipinas::Base do
  # Use Region as a concrete stand-in for Base (which is abstract).
  subject(:klass) { Pilipinas::Region }

  describe ".count" do
    it "returns the total number of regions" do
      expect(klass.count).to eq(17)
    end
  end

  describe ".first" do
    it "returns a non-nil record" do
      expect(klass.first).not_to be_nil
    end
  end

  describe ".last" do
    it "returns a non-nil record" do
      expect(klass.last).not_to be_nil
    end
  end

  describe ".all" do
    it "returns a frozen Array" do
      result = klass.all
      expect(result).to be_an(Array)
      expect(result).to be_frozen
    end
  end

  describe ".find_by" do
    context "when options hash is empty" do
      it "raises ArgumentError" do
        expect { klass.find_by({}) }.to raise_error(ArgumentError)
      end
    end

    context "when attribute is :code" do
      it "returns the matching record" do
        expect(klass.find_by(code: "1")).not_to be_nil
      end
    end

    context "when attribute is :name" do
      it "returns the matching record" do
        expect(klass.find_by(name: "NCR - National Capital Region")).not_to be_nil
      end
    end

    context "when attribute is not supported" do
      it "raises Pilipinas::UnknownAttribute" do
        expect { klass.find_by(test: 0) }.to raise_error(Pilipinas::UnknownAttribute)
      end
    end
  end

  describe ".respond_to_missing?" do
    it "reports find_by_code as supported" do
      expect(klass.respond_to?(:find_by_code)).to be true
    end

    it "reports find_by_name as supported" do
      expect(klass.respond_to?(:find_by_name)).to be true
    end
  end

    describe ".reset_cache" do
      it "clears the cache" do
        klass.all # warm up the cache
        klass.reset_cache
        expect(Pilipinas::Cache.size).to eq(0)
      end
    end

    describe ".data_file (abstract)" do
      it "raises NotImplementedError when called directly on Base" do
        expect { Pilipinas::Base.send(:data_file) }.to raise_error(NotImplementedError)
      end
    end

    describe ".method_missing" do
      it "raises NoMethodError for names that do not start with find_by_" do
        expect { klass.totally_unknown_method }.to raise_error(NoMethodError)
      end
    end

    describe ".assoc_collection with missing file" do
      it "returns an empty array when the association file does not exist" do
        result = klass.assoc_collection(code: "nonexistent_99999", dir: "nonexistent_dir")
        expect(result).to eq([])
      end
    end

    describe "value object behaviour" do
      let(:record) { klass.first }

      it "is frozen" do
        expect(record).to be_frozen
      end

      it "exposes a String code" do
        expect(record.code).to be_a(String)
      end

      it "exposes a String name" do
        expect(record.name).to be_a(String)
      end

      it "implements == based on class + code" do
        same  = klass.find_by(code: record.code)
        other = klass.last
        expect(record).to eq(same)
        expect(record).not_to eq(other) unless record.code == other.code
      end

      it "returns a descriptive string from to_s" do
        expect(record.to_s).to include("Region")
        expect(record.to_s).to include(record.code)
        expect(record.to_s).to include(record.name)
      end

      it "returns an inspect string" do
        expect(record.inspect).to start_with("#<Pilipinas::Region")
        expect(record.inspect).to include(record.code.inspect)
      end

      it "returns an Integer from hash" do
        expect(record.hash).to be_an(Integer)
      end

      it "two equal records have the same hash" do
        same = klass.find_by(code: record.code)
        expect(record.hash).to eq(same.hash)
      end
    end
end
