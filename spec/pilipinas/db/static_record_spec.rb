# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pilipinas::Db::Concerns::StaticRecord' do
  # Use Region as a representative model that includes this concern.
  let(:model_class) { Pilipinas::Db::Region }

  describe '#readonly?' do
    context 'when enforce_readonly is true (default)' do
      it 'returns false for a new (unsaved) record' do
        record = model_class.new
        expect(record.readonly?).to be(false)
      end

      it 'returns true for a persisted record' do
        record = model_class.create!
        expect(record.readonly?).to be(true)
      end

      it 'raises ActiveRecord::ReadOnlyRecord on update attempt' do
        record = model_class.create!
        expect { record.update!(code: '99') }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end

    context 'when enforce_readonly is false' do
      # Isolate the class-level change to this example group only.
      around do |example|
        original = model_class.enforce_readonly
        model_class.enforce_readonly = false
        example.run
      ensure
        model_class.enforce_readonly = original
      end

      it 'returns false for a persisted record' do
        record = model_class.create!
        expect(record.readonly?).to be(false)
      end

      it 'allows updating a persisted record without raising' do
        record = model_class.create!
        expect { record.update!(code: '99') }.not_to raise_error
      end
    end
  end

  describe '.enforce_readonly' do
    it 'defaults to true' do
      expect(model_class.enforce_readonly).to be(true)
    end

    it 'is inherited by subclasses' do
      subclass = Class.new(model_class)
      expect(subclass.enforce_readonly).to be(true)
    end

    it 'can be overridden on a subclass without affecting the parent' do
      subclass = Class.new(model_class)
      subclass.enforce_readonly = false

      expect(subclass.enforce_readonly).to be(false)
      expect(model_class.enforce_readonly).to be(true)
    end
  end
end
