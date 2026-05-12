# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pilipinas::Cache do
  before { described_class.clear }

  describe ".keys" do
    it "returns an empty array when the cache is empty" do
      expect(described_class.keys).to eq([])
    end

    it "returns the cached keys after a fetch" do
      described_class.fetch("alpha") { "a" }
      described_class.fetch("beta")  { "b" }
      expect(described_class.keys).to contain_exactly("alpha", "beta")
    end
  end

  describe ".size" do
    it "returns 0 when the cache is empty" do
      expect(described_class.size).to eq(0)
    end

    it "returns the number of cached entries" do
      described_class.fetch("k1") { 1 }
      described_class.fetch("k2") { 2 }
      expect(described_class.size).to eq(2)
    end
  end

  describe ".fetch double-check locking" do
    it "skips the block when another writer already populated the key before the lock was acquired" do
      store = described_class.instance_variable_get(:@store)
      mutex = described_class.instance_variable_get(:@mutex)

      block_calls = 0

      # Simulate the race: another thread set the key between the fast-path check
      # (L28) and entry into the mutex block (L32).
      allow(mutex).to receive(:synchronize) do |&blk|
        store["race_key"] = "from_other_thread"
        blk.call
      end

      result = described_class.fetch("race_key") { block_calls += 1; "computed" }

      expect(result).to eq("from_other_thread")
      expect(block_calls).to eq(0)
    end
  end
end
