# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index do
  describe '.mappings_hash' do
    context 'with types definition' do
      before do
        stub_index(:geos) do
          mappings do
            {
              'properties' => {
                'age' => { 'type' => 'integer' },
              },
            }
          end

          define_type :city
          define_type :county
        end
      end

      specify do
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'properties' => {
              'age' => { 'type' => 'integer' },
            },
          },
        )
      end
    end

    context 'with types definition' do
      before do
        stub_index(:geos) do
          define_type :county do
            mappings('name' => { 'type' => 'string' })
          end

          define_type :city do
            mappings('name' => { 'type' => 'string' })
          end
        end
      end

      specify do
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'county' => {
              'properties' => {
                'name' => { 'type' => 'string' },
              },
            },
            'city' => {
              'properties' => {
                'name' => { 'type' => 'string' },
              },
            },
          },
        )
      end
    end
  end
end
