# frozen_string_literal: true

require 'spec_helper'
require 'support/esse_config'

RSpec.describe Esse::IndexSetting do
  describe '.as_json' do
    context 'with :paths parameter' do
      let(:paths) { [Esse.config.indices_directory.join('events_index/templates')] }

      it 'reads json from template as fallback' do
        loader = instance_double(Esse::TemplateLoader)
        expect(loader).to receive(:read).with('{setting,settings}')
          .and_return('analyzer' => { 'myanalyzer' => {} })
        expect(Esse::TemplateLoader).to receive(:new).with(paths).and_return(loader)

        model = described_class.new(paths: paths)
        expect(model.as_json).to eq('analyzer' => { 'myanalyzer' => {} })
      end
    end

    context 'with :body parameter' do
      subject { described_class.new(body: { 'analyzer' => { 'myanalyzer': {} } }).as_json }

      specify do
        expect(Esse::TemplateLoader).not_to receive(:new)
        is_expected.to eq('analyzer' => { 'myanalyzer': {} })
      end
    end
  end

  describe '.body' do
    let(:model) { described_class.new }

    context 'with defautl settings' do
      specify do
        with_config do
          expect(model.body).to eq({})
        end
      end
    end

    context 'with global settings' do
      specify do
        with_config(index_settings: { refresh_interval: '1s' }) do
          expect(model.body).to eq(refresh_interval: '1s')
        end
      end
    end
  end
end
