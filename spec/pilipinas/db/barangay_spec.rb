# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pilipinas::Db::Barangay, type: :model do
  describe 'associations' do
    subject(:record) { described_class.create! }

    it { is_expected.to belong_to(:city).optional }
  end

  describe 'traversal' do
    let!(:city)     { Pilipinas::Db::City.create!(location_id: 96_001) }
    let!(:barangay) { described_class.create!(location_id: 96_002, parent_id: 96_001) }

    it 'loads the parent city via the scoped association' do
      expect(barangay.city).to eq(city)
    end
  end
end
