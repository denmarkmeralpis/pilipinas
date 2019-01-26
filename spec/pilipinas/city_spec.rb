require 'spec_helper'

RSpec.describe Pilipinas::City do
  let(:city) { Pilipinas::City }

  describe '#all' do
    it 'returns array of cities' do
      expect(city.all).to be_an(Array)
    end

    it 'returns 1648 cities' do
      expect(city.all.count).to eq(1648)
    end
  end

  describe '#barangays' do
    it 'returns array of barangays' do
      expect(city.first.barangays).to be_an(Array)
    end
  end

  describe '#find_by' do
    context 'with included attributes' do
      it 'finds data thru code' do
        expect(city.find_by_code('18817')).to be_truthy
      end

      it 'finds data thru name' do
        expect(city.find_by_name('NAGA CITY')).to be_truthy
      end
    end

    context 'non existent attribute' do
      it 'raises an exception' do
        expect { city.find_by_something }.to raise_error(Pilipinas::UnknownAttribute)
      end
    end
  end
end
