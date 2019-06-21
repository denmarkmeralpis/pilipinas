require 'spec_helper'

RSpec.describe Pilipinas::Db::Province, type: :model do
  describe 'associations' do
    subject { described_class.create() }
    it { is_expected.to belong_to(:region) }
    it { is_expected.to have_many(:cities) }
  end
end
