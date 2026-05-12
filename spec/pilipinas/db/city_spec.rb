# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pilipinas::Db::City, type: :model do
  describe 'associations' do
    subject(:record) { described_class.create! }

    it { is_expected.to belong_to(:province).optional }
    it { is_expected.to have_many(:barangays) }
  end

  describe 'traversal' do
    let!(:province) { Pilipinas::Db::Province.create!(location_id: 97_001) }
    let!(:city)     { described_class.create!(location_id: 97_002, parent_id: 97_001) }
    let!(:barangay) { Pilipinas::Db::Barangay.create!(location_id: 97_003, parent_id: 97_002) }

    it 'traverses province and barangays via scoped associations' do
      expect(city.province).to eq(province)
      expect(city.barangays.to_a).to include(barangay)
    end
  end
end
