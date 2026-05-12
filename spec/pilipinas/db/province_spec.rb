# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pilipinas::Db::Province, type: :model do
  describe "associations" do
    subject(:record) { described_class.create! }

    it { is_expected.to belong_to(:region).optional }
    it { is_expected.to have_many(:cities) }
  end

  describe "traversal" do
    let!(:region)   { Pilipinas::Db::Region.create!(location_id: 98_001) }
    let!(:province) { described_class.create!(location_id: 98_002, parent_id: 98_001) }
    let!(:city)     { Pilipinas::Db::City.create!(location_id: 98_003, parent_id: 98_002) }

    it "traverses region and cities via scoped associations" do
      expect(province.region).to eq(region)
      expect(province.cities.to_a).to include(city)
    end
  end
end

