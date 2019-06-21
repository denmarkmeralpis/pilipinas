require 'spec_helper'

RSpec.describe Pilipinas::Province do
  let(:province) { Pilipinas::Province }

  describe '#all' do
    it 'returns array of provinces' do
      expect(province.all).to be_an(Array)
    end

    it 'returns 86 provinces' do
      expect(province.all.count).to eq(86)
    end
  end

  describe '#provinces' do
    it 'returns array of provinces' do
      expect(province.first.cities).to be_an(Array)
    end
  end

  describe '#find_by' do
    context 'with included attributes' do
      it 'finds data thru code' do
        expect(province.find_by_code('2')).to be_truthy
      end

      it 'finds data thru name' do
        expect(province.find_by_name('CAMARINES SUR')).to be_truthy
      end
    end

    context 'non existent attribute' do
      it 'raises an exception' do
        expect { province.find_by_something }.to raise_error(Pilipinas::UnknownAttribute)
      end
    end
  end
end
