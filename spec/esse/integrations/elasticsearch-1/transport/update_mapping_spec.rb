# frozen_string_literal: true

require 'spec_helper'

stack_describe 'elasticsearch', '1.x', Esse::Transport, '#update_mapping' do
  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        cluster.api.update_mapping(index: 'esse_unknow_index_name_v1', type: 'dummy', body: {})
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'updates the mapping' do
    es_client do |client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_v1"
      cluster.api.create_index(index: index_name, body: {
        settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
      })

      expect {
        cluster.api.update_mapping(index: index_name, type: 'dummy', body: {
          properties: {
            name: { type: 'string' },
          },
        })
      }.not_to raise_error
      mapping = client.indices.get_mapping(index: index_name)
      expect(mapping.dig(index_name, 'mappings', 'dummy', 'properties')).to eq(
        'name' => { 'type' => 'string' },
      )
    end
  end
end
