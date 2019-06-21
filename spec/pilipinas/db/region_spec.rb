require 'spec_helper'

RSpec.describe Pilipinas::Db::Region, type: :model do
  describe 'associations' do
    subject { described_class.create() }
    it { is_expected.to have_many(:provinces) }
  end
end
