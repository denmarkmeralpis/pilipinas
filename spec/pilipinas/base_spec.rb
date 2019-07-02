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

  describe '#find_by' do
    context 'when empty hash' do
      let(:empty_hash) { {} }

      it 'raises error' do
        expect { region.find_by(empty_hash) }.to raise_error(StandardError)
      end
    end

    context 'when hash is not empty' do
      let(:hash) { { code: 1 } }

      it { expect(region.find_by(hash)).to be_truthy }
    end

    context 'when hash is not registered' do
      let(:hash) { { test: 0 } }

      it 'raises an error' do
        expect { region.find_by(hash) }
          .to raise_error(Pilipinas::UnknownAttribute)
      end
    end
  end
end
