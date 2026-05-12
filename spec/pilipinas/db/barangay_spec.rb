# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pilipinas::Db::Barangay, type: :model do
  describe "associations" do
    subject(:record) { described_class.create! }

    it { is_expected.to belong_to(:city).optional }
  end
end

