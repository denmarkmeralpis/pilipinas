# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pilipinas::Db::Province, type: :model do
  describe "associations" do
    subject(:record) { described_class.create! }

    it { is_expected.to belong_to(:region).optional }
    it { is_expected.to have_many(:cities) }
  end
end

