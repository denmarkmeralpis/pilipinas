require 'spec_helper'

RSpec.describe Pilipinas::Db::Barangay, type: :model do
  describe 'associations' do
    subject { described_class.create() }
    it { is_expected.to belong_to(:city) }
  end
end
