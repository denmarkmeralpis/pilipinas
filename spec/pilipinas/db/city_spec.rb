# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pilipinas::Db::City, type: :model do
  describe "associations" do
    subject(:record) { described_class.create! }

    it { is_expected.to belong_to(:province).optional }
    it { is_expected.to have_many(:barangays) }
  end
end

