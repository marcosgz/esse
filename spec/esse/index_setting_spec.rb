# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::IndexSetting do
  describe '.to_h' do
    context 'with :paths parameter' do
      let(:paths) { [Esse.config.indices_directory.join('events_index/templates')] }

      it 'reads json from template as fallback' do
        loader = instance_double(Esse::TemplateLoader)
        expect(loader).to receive(:read).with('{setting,settings}')
          .and_return('analyzer' => { 'myanalyzer' => {} })
        expect(Esse::TemplateLoader).to receive(:new).with(paths).and_return(loader)

        model = described_class.new(paths: paths)
        expect(model.to_h).to eq('analyzer' => { 'myanalyzer' => {} })
      end
    end

    context 'with :body parameter' do
      subject { described_class.new(body: { 'analyzer' => { myanalyzer: {} } }).to_h }

      specify do
        expect(Esse::TemplateLoader).not_to receive(:new)
        is_expected.to eq('analyzer' => { myanalyzer: {} })
      end
    end
  end

  describe '.body' do
    context 'with default settings' do
      specify do
        reset_config!
        model = described_class.new
        expect(model.body).to eq({})
      end
    end

    context 'with global settings' do
      specify do
        model = described_class.new(globals: -> { { refresh_interval: '1s' } })
        expect(model.body).to eq(refresh_interval: '1s')
      end

      it 'overrides global settings' do
        model = described_class.new(body: { refresh_interval: '5s' }, globals: -> { { refresh_interval: '1s' } })
        expect(model.body).to eq(refresh_interval: '5s')
      end

      it 'recursive merges all configs global' do
        globals = -> {
          {
            analysis: {
              analyzer: {
                default: {
                  tokenizer: :standard,
                  filter: %i[standard lowercase],
                },
              },
            },
          }
        }
        model = described_class.new(
          body: {
            analysis: {
              analyzer: {
                remove_html: {
                  type: :custom,
                  char_filter: :html_strip,
                }
              }
            }
          },
          globals: globals
        )
        expect(model.body).to eq(
          analysis: {
            analyzer: {
              default: {
                tokenizer: :standard,
                filter: %i[standard lowercase],
              },
              remove_html: {
                type: :custom,
                char_filter: :html_strip,
              },
            },
          },
        )
      end
    end
  end
end
