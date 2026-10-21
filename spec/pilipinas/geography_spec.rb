# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'digest'

RSpec.describe 'September 2026 PSGC geography' do
  it 'preserves the archived source bytes identified by the manifest and runtime metadata' do
    sources = File.expand_path('../../sources', __dir__)
    manifest = JSON.parse(File.read(File.join(sources, 'manifest.json')))
    expect(Pilipinas.metadata['files']).to eq(manifest['files'])
    manifest.fetch('files').each do |source|
      expect(Digest::SHA256.file(File.join(sources, source.fetch('file'))).hexdigest)
        .to eq(source.fetch('sha256'))
    end
  end

  it 'uses the dated official publication and preserves ten-digit identifiers' do
    expect(Pilipinas.metadata.dig('psgc', 'snapshot_date')).to eq('2026-09-30')
    expect(Pilipinas.metadata.dig('psgc', 'release_date')).to eq('2026-10-12')
    expect(Pilipinas::Region.find_by_code('0100000000').name).to eq('Region I (Ilocos Region)')
    expect(Pilipinas::City.where(level: 'City').size).to eq(149)
    expect(Pilipinas::City.where(level: 'Mun').size).to eq(1493)
  end

  it 'has globally unique official codes, valid parent types and consistent ancestry' do
    types = [Pilipinas::Region, Pilipinas::Province, Pilipinas::City, Pilipinas::Barangay,
             Pilipinas::Submunicipality, Pilipinas::Area]
    records = types.flat_map(&:all)
    by_code = records.to_h { |record| [record.code, record] }
    expect(by_code.size).to eq(records.size)
    allowed = { 'Prov' => %w[Reg], 'Area' => %w[Reg], 'City' => %w[Prov Reg Area],
                'Mun' => %w[Prov Reg Area], 'SubMun' => %w[City], 'Bgy' => %w[City Mun SubMun] }
    errors = records.filter_map do |record|
      next "Invalid code #{record.code}" unless record.code.match?(/\A\d{10}\z/)
      next if record.level == 'Reg'

      parent = by_code[record.parent_code]
      next "Invalid parent #{record.code}" unless parent && allowed.fetch(record.level).include?(parent.level)
      next "Wrong region #{record.code}" unless (parent.region_code || parent.code) == record.region_code

      if record.level == 'Bgy'
        city_level = by_code.fetch(record.city_code).level
        next "Wrong city #{record.code}" unless %w[City Mun].include?(city_level)
      end
    end
    expect(errors).to eq([])
  end

  it 'reaches every city and barangay exactly once from regions' do
    cities = Pilipinas::Region.all.flat_map(&:cities)
    barangays = cities.flat_map(&:barangays)
    expect(cities.map(&:code).sort).to eq(Pilipinas::City.all.map(&:code).sort)
    expect(barangays.map(&:code).sort).to eq(Pilipinas::Barangay.all.map(&:code).sort)
  end

  it 'requires an administrative province except for the explicit province-independent cases' do
    errors = Pilipinas::City.all.filter_map do |city|
      if city.province
        next "Wrong province parent #{city.code}" unless city.parent == city.province

        next
      end

      if city.level == 'City' && %w[HUC ICC].include?(city.city_class)
        next "Wrong independent city parent #{city.code}" unless city.parent == city.region
      elsif %w[0990100000 1999900000].include?(city.area_code)
        next "Wrong area parent #{city.code}" unless city.area && city.parent == city.area
      elsif city.code == '1381701000' && city.region_code == '1300000000'
        next "Wrong Pateros parent #{city.code}" unless city.parent == city.region
      else
        "Missing administrative province #{city.code}"
      end
    end
    expect(errors).to eq([])
  end

  it 'traverses a province address from region through municipality to barangay and back' do
    region = Pilipinas::Region.find_by_code('1400000000')
    province = region.provinces.find { |p| p.name == 'Abra' }
    city = province.cities.find { |c| c.name == 'Peñarrubia' }
    barangay = city.barangays.first
    expect(barangay.city).to equal(city)
    expect(barangay.province).to equal(province)
    expect(barangay.region).to equal(region)
    expect(barangay.parent).to equal(city)
    expect(province.parent).to equal(region)
    expect(region.parent).to be_nil
  end

  it 'includes NIR, BARMM, the Maguindanao split, Sulu in Region IX and the SGA municipalities' do
    nir = Pilipinas::Region.find_by_code('1800000000')
    expect(nir.provinces.map(&:name)).to contain_exactly('Negros Occidental', 'Negros Oriental', 'Siquijor')
    barmm = Pilipinas::Region.find_by_code('1900000000')
    expect(barmm.provinces.map(&:name)).to include('Maguindanao del Norte', 'Maguindanao del Sur')
    expect(Pilipinas::Province.find_by_name('Sulu').region.code).to eq('0900000000')
    area = barmm.areas.find { |a| a.name == 'Special Geographic Area' }
    expect(area.cities.size).to eq(8)
    expect(area.cities.sum { |city| city.barangays.size }).to eq(63)
    expect(area.cities.map(&:province)).to all(be_nil)
    expect(area.cities.first.area).to equal(area)
  end

  it 'keeps NCR and Manila districts out of administrative province/municipality totals' do
    ncr = Pilipinas::Region.find_by_code('1300000000')
    expect(ncr.provinces).to eq([])
    expect(ncr.cities.size).to eq(17)
    manila = ncr.cities.find { |c| c.name == 'City of Manila' }
    expect(manila.submunicipalities.size).to eq(14)
    expect(manila.barangays.size).to eq(897)
    tondo = manila.submunicipalities.find { |d| d.name == 'Tondo I/II' }
    expect(tondo.barangays.first.parent).to equal(tondo)
    expect(tondo.barangays.first.city).to equal(manila)
    expect(tondo.barangays.first.submunicipality).to equal(tondo)
    expect(manila.province).to be_nil
  end

  it 'exposes province-independent cities without assigning them an administrative province' do
    naga = Pilipinas::City.find_by_code('0501724000')
    expect(naga.city_class).to eq('ICC')
    expect(naga.province).to be_nil
    expect(naga.psgc_province_code).to eq('0501700000')
    expect(naga.region.cities_without_province).to include(naga)
    expect(Pilipinas::Province.find_by_code('0501700000').cities).not_to include(naga)
    lucena = Pilipinas::City.find_by_code('0431200000')
    expect(lucena.name).to eq('City of Lucena')
    expect(lucena.note).to include('statistical purposes')
    isabela = Pilipinas::Area.find_by_code('0990100000')
    expect(isabela.cities.first.province).to be_nil
    expect(isabela.cities.first.region.code).to eq('0900000000')
  end

  it 'preserves duplicate names under different parents and requires disambiguation' do
    expect(Pilipinas::City.where(name: 'City of Naga').map(&:region_code)).to contain_exactly('0500000000',
                                                                                              '0700000000')
    expect { Pilipinas::City.find_by_name('City of Naga') }.to raise_error(Pilipinas::AmbiguousMatch)
    expect(Pilipinas::City.find_by(name: 'City of Naga', province_code: '0702200000').code).to eq('0702234000')
    expect(Pilipinas::Barangay.where(name: 'Casay').size).to be > 1
    expect { Pilipinas::Barangay.find_by_name('Casay') }.to raise_error(Pilipinas::AmbiguousMatch)
  end

  it 'includes the latest correction and transferred EMBO barangays' do
    expect(Pilipinas::Barangay.find_by_code('1001322005').name).to eq('Lambagan')
    taguig = Pilipinas::City.find_by_code('1381500000')
    expect(taguig.barangays.map(&:name)).to include('Pembo', 'Comembo', 'East Rembo', 'West Rembo')
    expect(Pilipinas::City.find_by_code('1380300000').barangays.map(&:name)).not_to include('Pembo')
  end

  it 'provides explicit legacy mappings without treating internal IDs as official codes' do
    mapping = Pilipinas.legacy_lookup(type: :cities, code: '18817')
    expect(mapping['status']).to eq('matched')
    expect(mapping['candidates']).to eq([{ 'type' => 'cities', 'code' => '0501724000' }])
    expect(Pilipinas::City.find_by_code('18817')).to be_nil
    expect(Pilipinas.legacy_lookup(type: :provinces, code: '2')['status']).to eq('missing')
    expect(Pilipinas.legacy_lookup(type: :cities, code: 'not-an-old-id')).to be_nil
    expect(mapping['candidates'].first).to be_frozen
  end

  it 'runs the same public lookups in plain Ruby without ActiveRecord or network clients' do
    code = <<~RUBY
      require 'pilipinas'
      abort if defined?(ActiveRecord) || defined?(Net::HTTP)
      abort unless Pilipinas::City.find_by_code('1400117000').barangays.any?
      abort unless Pilipinas::Postal.lookup(locality: 'Pandacan', province: 'Metro Manila').suggestion == '1011'
    RUBY
    output, status = Open3.capture2e(RbConfig.ruby, '-Ilib', '-e', code)
    expect(status.success?).to be(true), output
  end

  it 'freezes metadata, records, strings and returned collections' do
    expect { Pilipinas.metadata['counts']['cities'] = 0 }.to raise_error(FrozenError)
    expect { Pilipinas::City.first.name << 'changed' }.to raise_error(FrozenError)
    expect { Pilipinas::City.first.barangays.clear }.to raise_error(FrozenError)
  end
end
