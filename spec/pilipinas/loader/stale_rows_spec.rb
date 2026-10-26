# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pilipinas::Loader::StaleRows do
  let(:now)            { Time.now.utc }
  let(:column_indexes) { { 'type' => 0, 'location_id' => 1 } }

  def clear_tables
    Pilipinas::Db::Region.delete_all
    Pilipinas::Db::Barangay.delete_all
  end

  # The db model specs leave rows behind, so start from empty tables too.
  before { clear_tables }
  after  { clear_tables }

  describe '.delete' do
    it 'deletes compact rows that have no location_id' do
      Pilipinas::Db::Region.create!(code: '1', name: 'NCR - National Capital Region')
      Pilipinas::Db::Region.create!(location_id: 1, code: '130000000', name: 'National Capital Region (NCR)')

      deleted = described_class.delete(Pilipinas::Db::Region, [['Locations::Region', 1]], column_indexes,
                                       'Locations::Region')

      expect(deleted).to eq(1)
      expect(Pilipinas::Db::Region.pluck(:location_id)).to eq([1])
    end

    it 'only keeps location ids of the given type' do
      Pilipinas::Db::Region.create!(location_id: 1, code: '130000000', name: 'National Capital Region (NCR)')
      records = [['Locations::Province', 1]]

      expect(described_class.delete(Pilipinas::Db::Region, records, column_indexes, 'Locations::Region')).to eq(1)
    end

    it 'deletes stale rows in batches and keeps current ones' do
      batch_size = Pilipinas::Loader::BATCH_SIZE
      rows = Array.new(batch_size + 2) do |i|
        { location_id: i + 1, code: "S#{i}", name: "Stale #{i}", created_at: now, updated_at: now }
      end
      Pilipinas::Db::Region.insert_all(rows)

      expect(Pilipinas::Db::Region).to receive(:where).with(location_id: nil).and_call_original
      expect(Pilipinas::Db::Region).to receive(:where).with(location_id: kind_of(Array)).twice.and_call_original
      allow(Pilipinas::Db::Region).to receive(:where).with(no_args).and_call_original

      deleted = described_class.delete(Pilipinas::Db::Region, [['Locations::Region', 1]], column_indexes,
                                       'Locations::Region')

      expect(deleted).to eq(batch_size + 1)
      expect(Pilipinas::Db::Region.pluck(:location_id)).to eq([1])
    end

    context 'when an application row still references a stale location' do
      before do
        ActiveRecord::Base.connection.create_table(:pilipinas_test_addresses, force: true) do |t|
          t.references :barangay, foreign_key: { to_table: :pilipinas_barangays }
        end
        barangay = Pilipinas::Db::Barangay.create!(location_id: 1659, code: '137501176', name: 'Barangay 176')
        ActiveRecord::Base.connection.execute(
          "INSERT INTO pilipinas_test_addresses (barangay_id) VALUES (#{barangay.id})"
        )
      end

      after { ActiveRecord::Base.connection.drop_table(:pilipinas_test_addresses) }

      it 'raises Pilipinas::Error naming the table' do
        expect { described_class.delete(Pilipinas::Db::Barangay, [], column_indexes, 'Locations::Barangay') }
          .to raise_error(Pilipinas::Error, /pilipinas_barangays.*foreign key/m)
      end
    end
  end
end
