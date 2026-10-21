# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pilipinas::Postal do
  it 'returns a supported exact postal locality match with source metadata' do
    result = described_class.lookup(locality: '  pandacan ', province: 'METRO MANILA')
    expect(result.status).to eq(:matched)
    expect(result.suggestion).to eq('1011')
    expect(result.candidates.first.locality).to eq('Pandacan')
    expect(described_class.metadata['retrieved_on']).to eq('2026-10-21')
    expect(described_class.metadata['publication_date']).to be_nil
  end

  it 'returns every candidate for a repeated locality and no arbitrary ZIP suggestion' do
    result = described_class.lookup(locality: 'Santa Maria')
    expect(result.status).to eq(:ambiguous)
    expect(result.zip_codes).to contain_exactly('8011', '2440')
    expect(result.suggestion).to be_nil
    expect(described_class.lookup(locality: 'Santa Maria', province: 'Pangasinan').suggestion).to eq('2440')
  end

  it 'returns missing for absent or contradictory labels, never a nearby or fuzzy match' do
    [{ locality: 'Makati', province: 'Metro Manila' }, { locality: 'Pandacan', province: 'Cebu' },
     { locality: 'Pandacan', region: 'Region 1 (Ilocos Region)' }, { locality: 'Panda' },
     { locality: '' }, { locality: nil }, { locality: 'Pandacan', province: '' }].each do |query|
      result = described_class.lookup(**query)
      expect(result.status).to eq(:missing)
      expect(result.candidates).to eq([])
      expect(result.suggestion).to be_nil
    end
  end

  it 'makes the malformed PHLPost source row visible without inventing its ZIP' do
    result = described_class.lookup(locality: 'Cajidiocan', province: 'Romblon')
    expect(result.status).to eq(:missing)
    expect(result.rejected_rows.first).to include('zip_code' => 'Cajidiocan',
                                                  'reason' => 'Source ZIP is not four digits')
    expect(result.suggestion).to be_nil
  end

  it 'keeps postal results immutable' do
    result = described_class.lookup(locality: 'Pandacan')
    expect(result).to be_frozen
    expect(result.candidates).to be_frozen
    expect(result.candidates.first).to be_frozen
    expect(result.candidates.first.zip_code).to be_frozen
    expect(described_class.lookup(locality: 'Cajidiocan').rejected_rows.first).to be_frozen
  end
end
