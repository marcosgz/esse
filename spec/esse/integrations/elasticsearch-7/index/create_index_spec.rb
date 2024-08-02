# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/index_create_index'

stack_describe 'elasticsearch', '7.x', Esse::Index, '.create_index' do
  include_examples 'index.create_index'

  context 'with settings and mappings' do
    before do
      stub_index(:dummies) do
        settings do
          {
            index: {
              number_of_shards: 1,
              number_of_replicas: 0
            }
          }
        end
        mappings do
          {
            properties: {
              age: { type: 'integer' },
            }
          }
        end
        repository :dummy
      end
    end

    it 'creates index with settings and mappings' do
      es_client do |client, _conf, cluster|
        DummiesIndex.create_index(alias: true, suffix: 'v1')

        response = client.indices.get_mapping(index: real_name = DummiesIndex.index_name(suffix: 'v1'))
        expect(response.dig(real_name, 'mappings', 'properties')).to eq('age' => { 'type' => 'integer' })
        response = client.indices.get_settings(index: real_name)
        expect(response.dig(real_name, 'settings', 'index', 'number_of_shards')).to eq('1')
      end
    end
  end
end
