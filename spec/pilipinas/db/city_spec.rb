require 'spec_helper'

RSpec.describe Pilipinas::Db::City, type: :model do
  describe 'associations' do
    subject { described_class.create() }
    it { is_expected.to belong_to(:province) }
    it { is_expected.to have_many(:barangays) }
  end
end
