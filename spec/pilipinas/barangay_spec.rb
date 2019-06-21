require 'spec_helper'

RSpec.describe Pilipinas::Barangay do
  let(:barangay) { Pilipinas::Barangay }

  describe '#all' do
    it 'returns array of barangays' do
      expect(barangay.all).to be_an(Array)
    end

    it 'returns 42027 barangays' do
      expect(barangay.all.count).to eq(42_027)
    end
  end

  describe '#find_by' do
    context 'with included attributes' do
      it 'finds data thru code' do
        expect(barangay.find_by_code('21687')).to be_truthy
      end

      it 'finds data thru name' do
        expect(barangay.find_by_name('Casay')).to be_truthy
      end
    end

    context 'non existent attribute' do
      it 'raises an exception' do
        expect { barangay.find_by_something }.to raise_error(Pilipinas::UnknownAttribute)
      end
    end
  end
end
