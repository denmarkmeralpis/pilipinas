require 'spec_helper'

RSpec.describe Pilipinas::Region do
   let(:region) { Pilipinas::Region }

   describe '#all' do
      it 'returns array of regions' do
         expect(region.all).to be_an(Array)
      end

      it 'returns 17 regions' do
         expect(region.all.count).to eq(17)
      end
   end

   describe '#provinces' do
      it 'returns array of provinces' do
         expect(region.first.provinces).to be_an(Array)
      end
   end

   describe '#find_by' do
      context 'with included attributes' do
         it 'finds data thru code' do
            expect(region.find_by_code("17744")).to be_truthy
         end

         it 'finds data thru name' do
            expect(region.find_by_name('REGION V (Bicol Region)')).to be_truthy
         end
      end

      context 'non existent attribute' do
         it 'raises an exception' do
            expect { region.find_by_something }.to raise_error(Pilipinas::UnknownAttribute)
         end
      end
   end
end