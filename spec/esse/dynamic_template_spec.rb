# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::DynamicTemplate do
  describe '.any?' do
    specify do
      expect(described_class.new(nil)).not_to be_any
    end

    specify do
      expect(described_class.new([])).not_to be_any
    end

    specify do
      expect(described_class.new({})).not_to be_any
    end

    specify do
      expect(described_class.new('test')).not_to be_any
    end

    specify do
      expect(described_class.new(test: {})).to be_any
    end

    specify do
      expect(described_class.new([{test: { foo: :bar }}])).to be_any
    end
  end

  describe '[]=' do
    specify do
      model = described_class.new(nil)
      model[:foo] = :bar
      expect(model.to_a).to eq([{ foo: :bar }])
    end

    specify do
      model = described_class.new('my_text_tpl' => { 'match_mapping_type' => 'text' },)
      model['my_keyword_tpl'] = { 'match_mapping_type' => 'keyword' }
      expect(model.to_a).to eq([
        { my_text_tpl: { match_mapping_type: 'text' } },
        { my_keyword_tpl: { match_mapping_type: 'keyword' } },
      ])
    end

    specify do
      model = described_class.new([{'my_text_tpl' => { 'match_mapping_type' => 'text' }}])
      model['my_keyword_tpl'] = { 'match_mapping_type' => 'keyword' }
      expect(model.to_a).to eq([
        { my_text_tpl: { match_mapping_type: 'text' } },
        { my_keyword_tpl: { match_mapping_type: 'keyword' } },
      ])
    end
  end

  describe '.merge!' do
    # rubocop:disable Performance/RedundantMerge
    specify do
      model = described_class.new(nil)
      model.merge!(foo: :bar)
      expect(model.to_a).to eq([{ foo: :bar }])
    end

    specify do
      model = described_class.new('my_text_tpl' => { 'match_mapping_type' => 'text' },)
      model.merge!('my_keyword_tpl' => { 'match_mapping_type' => 'keyword' })
      expect(model.to_a).to eq([
        { my_text_tpl: { match_mapping_type: 'text' } },
        { my_keyword_tpl: { match_mapping_type: 'keyword' } },
      ])
    end

    specify do
      model = described_class.new([{'my_text_tpl' => { 'match_mapping_type' => 'text' }}])
      model.merge!('my_keyword_tpl' => { 'match_mapping_type' => 'keyword' })
      expect(model.to_a).to eq([
        { my_text_tpl: { match_mapping_type: 'text' } },
        { my_keyword_tpl: { match_mapping_type: 'keyword' } },
      ])
    end

    specify do
      model = described_class.new('my_text_tpl' => { 'match_mapping_type' => 'text' },)
      model.merge!([{'my_keyword_tpl' => { 'match_mapping_type' => 'keyword' }}])
      expect(model.to_a).to eq([
        { my_text_tpl: { match_mapping_type: 'text' } },
        { my_keyword_tpl: { match_mapping_type: 'keyword' } },
      ])
    end

    specify do
      model = described_class.new(my_text_tpl: { match_mapping_type: 'string' })
      model.merge!([{'my_text_tpl' => { 'match_mapping_type' => 'text' }}])
      expect(model.to_a).to eq([{ my_text_tpl: { match_mapping_type: 'text' } }])
    end
    # rubocop:enable Performance/RedundantMerge
  end

  describe '.to_a' do
    specify do
      model = described_class.new(nil)
      expect(model.to_a).to eq([])
    end

    specify do
      model = described_class.new([])
      expect(model.to_a).to eq([])
    end

    specify do
      model = described_class.new({})
      expect(model.to_a).to eq([])
    end

    specify do
      model = described_class.new('test')
      expect(model.to_a).to eq([])
    end

    specify do
      model = described_class.new(test: {})
      expect(model.to_a).to eq([{ test: {} }])
    end

    specify do
      model = described_class.new([{test: { foo: :bar }}])
      expect(model.to_a).to eq([{ test: { foo: :bar } }])
    end
  end

  describe '.dup' do
    specify do
      hash = {}
      model = described_class.new(hash)
      expect { model.dup.merge!(foo: :bar) }.not_to change { hash }
      expect(model.to_a).to eq([])
    end
  end
end
