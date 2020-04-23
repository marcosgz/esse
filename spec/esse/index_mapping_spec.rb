# frozen_string_literal: true

require 'spec_helper'
require 'support/esse_config'

RSpec.describe Esse::IndexMapping do
  describe '.empty?' do
    specify do
      expect(described_class.new).to be_empty
    end

    specify do
      expect(described_class.new(body: {})).to be_empty
    end

    specify do
      expect(described_class.new(body: { foo: :bar })).not_to be_empty
    end
  end

  describe '.as_json' do
    let(:paths) { [Esse.config.indices_directory.join('events_index')] }
    let(:filenames) { ['{mapping,mappings}'] }

    it 'returns the instance variable when it is not empty' do
      mapping = described_class.new(body: { 'pk' => { 'type' => 'long' } })

      expect(mapping.as_json).to eq('pk' => { 'type' => 'long' })
    end

    it 'reads json from template as fallback' do
      loader = instance_double(Esse::TemplateLoader)
      expect(loader).to receive(:read).with('{mapping,mappings}')
        .and_return('pk' => { 'type' => 'long' })
      expect(Esse::TemplateLoader).to receive(:new).with(paths).and_return(loader)

      mapping = described_class.new(paths: paths, filenames: filenames)
      expect(mapping.as_json).to eq('pk' => { 'type' => 'long' })
    end
  end
end
