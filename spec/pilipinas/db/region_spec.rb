# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pilipinas::Db::Region, type: :model do
  describe 'associations' do
    subject(:record) { described_class.create! }

    it { is_expected.to have_many(:provinces) }
  end

  describe 'traversal' do
    let!(:region)   { described_class.create!(location_id: 99_001) }
    let!(:province) { Pilipinas::Db::Province.create!(location_id: 99_002, parent_id: 99_001) }

    it 'loads provinces via the scoped association' do
      expect(region.provinces.to_a).to include(province)
    end
  end
end
