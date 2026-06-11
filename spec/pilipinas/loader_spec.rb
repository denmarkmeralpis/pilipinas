# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pilipinas::Loader do
  after do
    Pilipinas::Db::Barangay.delete_all
    Pilipinas::Db::City.delete_all
    Pilipinas::Db::Province.delete_all
    Pilipinas::Db::Region.delete_all
  end

  describe '.run' do
    it 'seeds all four geographic tables' do
      Pilipinas::Loader.run

      expect(Pilipinas::Db::Region.count).to be > 0
      expect(Pilipinas::Db::Province.count).to be > 0
      expect(Pilipinas::Db::City.count).to be > 0
      expect(Pilipinas::Db::Barangay.count).to be > 0
    end

    it 'seeds complete attributes from the full data file' do
      Pilipinas::Loader.run

      expect(Pilipinas::Db::Region.find_by(location_id: 1)).to have_attributes(
        code: '130000000',
        lft: 1,
        rgt: 3484,
        longitude: '121.0222565',
        latitude: '14.6090537'
      )
      expect(Pilipinas::Db::Province.find_by(location_id: 2)).to have_attributes(
        parent_id: 1,
        code: '133900000'
      )
      expect(Pilipinas::Db::City.find_by(location_id: 4)).to have_attributes(
        parent_id: 2,
        code: '133901000',
        city: true,
        income_class: '-',
        urban_rural: 'Urban',
        district: '1st/2nd'
      )
      expect(Pilipinas::Db::Barangay.find_by(location_id: 5)).to have_attributes(
        parent_id: 4,
        code: '133901001',
        urban_rural: 'Urban'
      )
    end

    it 'is idempotent – running twice yields the same region count' do
      Pilipinas::Loader.run
      count = Pilipinas::Db::Region.count
      Pilipinas::Loader.run
      expect(Pilipinas::Db::Region.count).to eq(count)
    end
  end

  describe '.seed (private)' do
    it 'does nothing when the YAML file contains no records' do
      allow(Psych).to receive(:load_file).and_return(nil)
      Pilipinas::Loader.send(:seed, Pilipinas::Db::Region, 'regions.yml')
      expect(Pilipinas::Db::Region.count).to eq(0)
    end

    it 'inserts transformed records from a legacy YAML file' do
      records = [{ code: 'TEST', name: 'Test Region' }]

      allow(Psych).to receive(:load_file).and_return(records)
      expect(Pilipinas::Loader).to receive(:bulk_insert) do |model, batch|
        expect(model).to eq(Pilipinas::Db::Region)
        expect(batch).to contain_exactly(
          include('code' => 'TEST', 'name' => 'Test Region', 'created_at' => be_a(Time), 'updated_at' => be_a(Time))
        )
      end

      Pilipinas::Loader.send(:seed, Pilipinas::Db::Region, 'regions.yml')
    end
  end

  describe '.seed_full_data (private)' do
    it 'does not perform an extra insert when the final batch is empty' do
      column_indexes = { 'type' => 0, 'code' => 1, 'name' => 2 }
      records = Array.new(described_class.const_get(:BATCH_SIZE)) { ['Locations::Region', 'TEST', 'Test Region'] }

      expect(Pilipinas::Loader).to receive(:bulk_insert).once

      Pilipinas::Loader.send(
        :seed_full_data,
        Pilipinas::Db::Region,
        records,
        column_indexes,
        'Locations::Region',
        %w[code name]
      )
    end
  end

  describe '.bulk_insert (private)' do
    let(:now)   { Time.now.utc }
    let(:batch) { [{ 'code' => 'BTEST', 'name' => 'Bulk Test', 'created_at' => now, 'updated_at' => now }] }

    context 'when upsert_all raises ArgumentError (unique index missing)' do
      let(:model) do
        Class.new do
          def self.table_name = 'pilipinas_regions'
          def self.upsert_all(_batch, **_opts) = raise(ArgumentError, 'No unique index found for code')
        end
      end

      it 'raises Pilipinas::Error' do
        expect { Pilipinas::Loader.send(:bulk_insert, model, batch) }
          .to raise_error(Pilipinas::Error)
      end

      it 'includes the table name in the error message' do
        expect { Pilipinas::Loader.send(:bulk_insert, model, batch) }
          .to raise_error(Pilipinas::Error, /pilipinas_regions/)
      end

      it 'includes the generator command in the error message' do
        expect { Pilipinas::Loader.send(:bulk_insert, model, batch) }
          .to raise_error(Pilipinas::Error, /rails generate pilipinas:code_indexes/)
      end

      it 'includes the migrate command in the error message' do
        expect { Pilipinas::Loader.send(:bulk_insert, model, batch) }
          .to raise_error(Pilipinas::Error, /rails db:migrate/)
      end
    end

    context 'when model responds to insert_all but not upsert_all' do
      let(:model) do
        Class.new do
          def self.insert_all(_batch) = nil
        end
      end

      it 'calls insert_all' do
        expect(model).to receive(:insert_all).with(batch)
        Pilipinas::Loader.send(:bulk_insert, model, batch)
      end
    end

    context 'when model responds to neither upsert_all nor insert_all' do
      let(:model) do
        Class.new do
          def self.unscoped = self
          def self.create!(_attrs) = nil
        end
      end

      it 'calls create! for each row' do
        expect(model).to receive(:create!).with(batch.first)
        Pilipinas::Loader.send(:bulk_insert, model, batch)
      end
    end
  end

  describe '.timestamp (private)' do
    it 'returns a Time instance when ActiveSupport is available' do
      expect(Pilipinas::Loader.send(:timestamp)).to be_a(Time)
    end

    it 'falls back to Time.now.utc when Time.current is not defined' do
      current_method = Time.method(:current)
      Time.singleton_class.undef_method(:current)

      result = Pilipinas::Loader.send(:timestamp)
      expect(result).to be_a(Time)
    ensure
      Time.define_singleton_method(:current) { current_method.call }
    end
  end
end
