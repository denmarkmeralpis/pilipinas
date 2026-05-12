# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pilipinas::Barangay do
  subject(:klass) { described_class }

  describe '.all' do
    it 'returns an Array' do
      expect(klass.all).to be_an(Array)
    end

    it 'returns 42,027 barangays' do
      expect(klass.all.count).to eq(42_027)
    end
  end

  describe '.find_by_code' do
    it 'finds a barangay by code' do
      expect(klass.find_by_code('21687')).to be_a(described_class)
    end

    it 'returns nil for an unknown code' do
      expect(klass.find_by_code('999999999')).to be_nil
    end
  end

  describe '.find_by_name' do
    it 'finds a barangay by name' do
      expect(klass.find_by_name('Casay')).to be_a(described_class)
    end

    it 'is case-insensitive' do
      lower = klass.find_by_name('casay')
      upper = klass.find_by_name('Casay')
      expect(lower).to eq(upper)
    end
  end

  describe '.find_by_something (unsupported attribute)' do
    it 'raises Pilipinas::UnknownAttribute' do
      expect { klass.find_by_something }.to raise_error(Pilipinas::UnknownAttribute)
    end
  end
end
