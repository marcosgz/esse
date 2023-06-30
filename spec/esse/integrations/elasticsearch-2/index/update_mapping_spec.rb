# frozen_string_literal: true

require 'spec_helper'

stack_describe 'elasticsearch', '2.x', Esse::Index, '.update_mapping' do
  include_context 'with geos index definition'

  before do
    GeosIndex.mappings do
      {
        state: {
          properties: {
            state_abbr: { type: 'string' },
          }
        }
      }
    end
  end

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.update_mapping(suffix: '2022', type: 'state')
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'update mappings from index definition' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: '2022')

      GeosIndex.mappings do
        {
          state: {
            properties: {
              state_abbr: { type: 'string' },
              new_field: { type: 'integer' },
            }
          }
        }
      end

      resp = nil
      expect {
        resp = GeosIndex.update_mapping(suffix: '2022', type: 'state')
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)

      mapping = client.indices.get_mapping(index: index_name = GeosIndex.index_name(suffix: '2022'))
      expect(mapping.dig(index_name, 'mappings', 'state', 'properties', 'new_field')).to eq(
        'type' => 'integer',
      )
    end
  end

  it 'update mappings from body argument' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: '2022')

      resp = nil
      expect {
        resp = GeosIndex.update_mapping(suffix: '2022', type: 'state', body: {
          state: {
            properties: {
              state_abbr: { type: 'string' },
              new_field: { type: 'integer' },
            }
          }
        })
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)

      mapping = client.indices.get_mapping(index: index_name = GeosIndex.index_name(suffix: '2022'))
      expect(mapping.dig(index_name, 'mappings', 'state', 'properties', 'new_field')).to eq(
        'type' => 'integer',
      )
    end
  end
end
