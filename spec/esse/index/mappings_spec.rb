# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index, '.mappings' do
  describe '.mappings_hash' do
    context 'with global mappings definition' do
      specify do
        index = Class.new(described_class)
        with_cluster_config(mappings: { properties: { name: { type: 'text' } } }) do |config|
          expect(index.mappings_hash).to eq(mappings: { properties: { name: { type: 'text' } } })
        end
      end
    end

    context 'with definition only on index level' do
      before do
        stub_index(:geos) do
          mappings do
            {
              properties: {
                age: { type: 'integer' },
              },
            }
          end

          repository :city
          repository :county
        end
      end

      specify do
        expect(GeosIndex.mappings_hash).to eq(
          mappings: {
            properties: {
              age: { type: 'integer' },
            },
          },
        )
      end
    end

    context 'with properties and dynamic_templates definition only on index level' do
      before do
        stub_index(:geos) do
          mappings do
            {
              properties: {
                age: { type: 'integer' },
              },
              dynamic_templates: [
                { test: {} }
              ]
            }
          end

          repository :city
          repository :county
        end
      end

      specify do
        expect(GeosIndex.mappings_hash).to eq(
          mappings: {
            dynamic_templates: [
              { test: {} }
            ],
            properties: {
              age: { type: 'integer' },
            },
          },
        )
      end
    end
  end
end
