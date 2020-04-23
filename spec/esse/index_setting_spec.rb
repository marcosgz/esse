# frozen_string_literal: true

require 'spec_helper'
require 'support/esse_config'

RSpec.describe Esse::IndexSetting do
  let(:index) { EventsIndex }

  before { stub_index(:events) }

  describe '.as_json' do
    context 'without arguments' do
      subject { described_class.new(index).as_json }

      it { is_expected.to eq({}) }

      it 'reads json from template as fallback' do
        loader = instance_double(Esse::TemplateLoader)
        expect(loader).to receive(:read).with('{setting,settings}')
          .and_return('analyzer' => { 'myanalyzer' => {} })
        expect(Esse::TemplateLoader).to receive(:new).with([
                                                             Esse.config.indices_directory.join('events_index/templates'),
                                                             Esse.config.indices_directory.join('events_index')
                                                           ]).and_return(loader)

        model = described_class.new(index)
        expect(model.as_json).to eq('analyzer' => { 'myanalyzer' => {} })
      end
    end

    context 'with arguments' do
      subject { described_class.new(index, analyzer: { myanalyzer: {} }).as_json }

      specify do
        expect(Esse::TemplateLoader).not_to receive(:new)
        is_expected.to eq(analyzer: { myanalyzer: {} })
      end
    end
  end

  describe '.body' do
    let(:model) { described_class.new(index) }

    before { reset_esse_config }

    it { expect(model.body).to eq({}) }

    context 'with global settings' do
      before do
        Esse.config do |c|
          c.index_settings = { refresh_interval: '1s' }
        end
      end

      it { expect(model.body).to eq(refresh_interval: '1s') }
    end
  end
end
