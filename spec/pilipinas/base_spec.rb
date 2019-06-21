require 'spec_helper'

RSpec.describe Pilipinas::Base do
  let(:region) { Pilipinas::Region }

  describe '#count' do
    it { expect(region.count).to eq(17) }
  end

  describe '#first' do
    it { expect(region.first).not_to be_nil }
  end

  describe '#last' do
    it { expect(region.last).not_to be_nil }
  end

  describe '#all' do
    it { expect(region.all).to be_truthy }
  end
end
