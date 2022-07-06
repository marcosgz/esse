# frozen_string_literal: true

require 'spec_helper'

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

  describe '.to_h' do
    let(:paths) { [Esse.config.indices_directory.join('events_index')] }
    let(:filenames) { ['{mapping,mappings}'] }

    it 'returns the instance variable when it is not empty' do
      mapping = described_class.new(body: { 'pk' => { 'type' => 'long' } })

      expect(mapping.to_h).to eq('pk' => { 'type' => 'long' })
    end

    it 'reads json from template as fallback' do
      loader = instance_double(Esse::TemplateLoader)
      expect(loader).to receive(:read).with('{mapping,mappings}')
        .and_return('pk' => { 'type' => 'long' })
      expect(Esse::TemplateLoader).to receive(:new).with(paths).and_return(loader)

      mapping = described_class.new(paths: paths, filenames: filenames)
      expect(mapping.to_h).to eq('pk' => { 'type' => 'long' })
    end
  end

  describe '.body' do
    context 'with default mappings' do
      specify do
        reset_config!
        model = described_class.new
        expect(model.body).to eq({})
      end
    end

    context 'with global explicit mappings' do
      let(:fields) do
        {
          slug: { type: 'keyword' },
        }
      end

      specify do
        globals = -> { { properties: fields } }
        model = described_class.new(globals: globals)
        expect(model.body).to eq(properties: fields)
      end

      it 'overrides global mappings' do
        globals = -> { { properties: fields } }
        model = described_class.new(body: { properties: { slug: { type: 'text' } } }, globals: globals)
        expect(model.body).to eq(properties: { slug: { type: 'text' } })
      end

      it 'recursive merges all configs global' do
        globals = -> {
          {
            properties: {
              slug: { type: 'keyword' },
              title: { type: 'text' },
            },
          }
        }

        model = described_class.new(
          body: {
            properties: {
              slug: { type: 'text' },
              title: { type: 'text' },
            },
          },
          globals: globals,
        )
        expect(model.body).to eq(
          properties: {
            slug: { type: 'text' },
            title: { type: 'text' },
          },
        )
      end
    end

    # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/dynamic-templates.html
    context 'with global dynamic templates' do
      let(:global_template) do
        {
          my_string_tpl: {
            match_mapping_type: 'string',
          }
        }
      end

      specify do
        globals = -> { { dynamic_templates: [global_template] } }
        model = described_class.new(globals: globals)
        expect(model.body).to eq(dynamic_templates: [global_template])
      end

      it 'overrides global dynamic templates' do
        globals = -> { { dynamic_templates: [global_template] } }
        model = described_class.new(body: { dynamic_templates: [{ my_string_tpl: { match_mapping_type: 'text' } }] }, globals: globals)
        expect(model.body).to eq(dynamic_templates: [{ my_string_tpl: { match_mapping_type: 'text' } }])
      end

      it 'recursive merges all configs global' do
        globals = -> {
          {
            dynamic_templates: [
              global_template,
              {
                my_string_tpl: {
                  match_mapping_type: 'string',
                },
              },
            ],
          }
        }

        model = described_class.new(
          body: {
            dynamic_templates: [
              { my_text_tpl: { match_mapping_type: 'text' } },
            ],
          },
          globals: globals,
        )
        expect(model.body).to eq(
          dynamic_templates: [
            global_template,
            { my_text_tpl: { match_mapping_type: 'text' } },
          ],
        )
      end

      it 'updates and merge the global template with the local' do
        globals = -> {
          {
            dynamic_templates: [
              global_template,
              {
                my_string_tpl: {
                  match_mapping_type: 'string',
                },
              },
            ],
          }
        }

        model = described_class.new(
          body: {
            dynamic_templates: [
              { 'my_string_tpl' => { match_mapping_type: 'text' } },
              { 'my_text_tpl' => { match_mapping_type: 'text' } },
            ],
          },
          globals: globals,
        )
        expect(model.body).to eq(
          dynamic_templates: [
            { my_string_tpl: { match_mapping_type: 'text' } },
            { my_text_tpl: { match_mapping_type: 'text' } },
          ],
        )
      end

      it 'convert global hash template to array' do
        globals = -> {
          {
            dynamic_templates: {
              my_string_tpl: {
                match_mapping_type: 'keyword',
              },
            },
          }
        }

        model = described_class.new(
          body: {
            dynamic_templates: [
              { 'my_text_tpl' => { match_mapping_type: 'text' } },
            ],
          },
          globals: globals,
        )
        expect(model.body).to eq(
          dynamic_templates: [
            { my_string_tpl: { match_mapping_type: 'keyword' } },
            { my_text_tpl: { match_mapping_type: 'text' } },
          ],
        )
      end

      it 'converts local hash template to array' do
        globals = -> {
          {
            dynamic_templates: [
              global_template,
            ],
          }
        }

        model = described_class.new(
          body: {
            dynamic_templates: {
              'my_text_tpl' => { match_mapping_type: 'text' },
            },
          },
          globals: globals,
        )
        expect(model.body).to eq(
          dynamic_templates: [
            { my_string_tpl: { match_mapping_type: 'string' } },
            { my_text_tpl: { match_mapping_type: 'text' } },
          ],
        )
      end
    end
  end
end
