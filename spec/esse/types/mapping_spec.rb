# frozen_string_literal: true

require 'spec_helper'
require 'support/esse_config'

RSpec.describe Esse::Types::Mapping do
  describe '.as_json' do
    before { stub_index(:events) { define_type(:event) } }

    it 'returns the instance variable when it is not empty' do
      mapping = described_class.new(EventsIndex::Event, { pk: { type: 'long' } })

      expect(mapping.as_json).to eq(pk: { type: 'long' })
    end

    it 'reads json from template as fallback' do
      loader = instance_double(Esse::TemplateLoader)
      expect(loader).to receive(:read).with('event_{mapping,mappings}', '{mapping,mappings}')
        .and_return('pk' => { 'type' => 'long' })
      expect(Esse::TemplateLoader).to receive(:new).with(
        [
          Esse.config.indices_directory.join('events_index/event'),
          Esse.config.indices_directory.join('events_index/templates'),
          Esse.config.indices_directory.join('events_index')
        ],
      ).and_return(loader)
      mapping = described_class.new(EventsIndex::Event)
      expect(mapping.as_json).to eq('pk' => { 'type' => 'long' })
    end
  end
end
