# frozen_string_literal: true

require 'spec_helper'

stack_describe 'elasticsearch', '1.x', 'elasticsearch update mappings' do
  before do
    stub_index(:dummies) do
      mappings do
        {
          dummy: {
            properties: {
              'title' => { 'type' => 'string', 'index' => 'not_analyzed' }
            }
          }
        }
      end

      repository :dummy do
      end
    end
  end

  describe '.update_mapping!' do
    specify do
      es_client do |_client, _conf, cluster|
        expect { DummiesIndex.elasticsearch.update_mapping!(type: 'dummy') }.to raise_error(
          Esse::Backend::NotFoundError,
        ).with_message(/\[#{cluster.index_prefix}_dummies\] missing/)
      end
    end

    specify do
      es_client do |_client, _conf, cluster|
        expect { DummiesIndex.elasticsearch.update_mapping!(suffix: 'v1', type: 'dummy') }.to raise_error(
          Esse::Backend::NotFoundError,
        ).with_message(/\[#{cluster.index_prefix}_dummies_v1\] missing/)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        mapping = client.indices.get_mapping(index: "#{cluster.index_prefix}_dummies")
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v1", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
          },
        )

        new_mapping = instance_double(
          Esse::IndexMapping,
          body: {
            'title' => { 'type' => 'string', 'index' => 'analyzed' },
          },
        )
        expect(DummiesIndex::Dummy).to receive(:mapping).and_return(new_mapping)
        expect { DummiesIndex.elasticsearch.update_mapping!(type: 'dummy') }.to raise_error(
          Esse::Backend::BadRequestError,
        ).with_message(/mapper \[title\] has different index_analyzer/)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        mapping = client.indices.get_mapping(index: "#{cluster.index_prefix}_dummies")
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v1", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
          },
        )

        new_mapping = instance_double(
          Esse::IndexMapping,
          body: {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
            'published' => { 'type' => 'boolean' },
          },
        )
        expect(DummiesIndex::Dummy).to receive(:mapping).and_return(new_mapping)
        expect(DummiesIndex.elasticsearch.update_mapping!(type: 'dummy')['acknowledged']).to eq(true)

        mapping = client.indices.get_mapping(index: "#{cluster.index_prefix}_dummies")
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v1", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
            'published' => { 'type' => 'boolean' },
          },
        )
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v2')['acknowledged']).to eq(true)
        mapping = client.indices.get_mapping(index: "#{cluster.index_prefix}_dummies*")
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v1", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
          },
        )
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v2", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
          },
        )

        new_mapping = instance_double(
          Esse::IndexMapping,
          body: {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
            'published' => { 'type' => 'boolean' },
          },
        )
        expect(DummiesIndex::Dummy).to receive(:mapping).and_return(new_mapping)
        expect(DummiesIndex.elasticsearch.update_mapping!(suffix: 'v1', type: 'dummy')['acknowledged']).to eq(true)

        mapping = client.indices.get_mapping(index: "#{cluster.index_prefix}_dummies*")
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v1", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
            'published' => { 'type' => 'boolean' },
          },
        )
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v2", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
          },
        )
      end
    end
  end

  describe '.update_mapping' do
    specify do
      es_client do |_client, _conf, _cluster|
        expect(DummiesIndex.elasticsearch.update_mapping(type: 'dummy')).to eq('errors' => true)
      end
    end

    specify do
      es_client do |_client, _conf, _cluster|
        expect(DummiesIndex.elasticsearch.update_mapping(suffix: 'v1', type: 'dummy')).to eq('errors' => true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        mapping = client.indices.get_mapping(index: "#{cluster.index_prefix}_dummies")
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v1", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
          },
        )

        new_mapping = instance_double(
          Esse::IndexMapping,
          body: {
            'title' => { 'type' => 'string', 'index' => 'analyzed' },
          },
        )
        expect(DummiesIndex::Dummy).to receive(:mapping).and_return(new_mapping)
        expect(DummiesIndex.elasticsearch.update_mapping(type: 'dummy')).to eq('errors' => true)
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
        mapping = client.indices.get_mapping(index: "#{cluster.index_prefix}_dummies")
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v1", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
          },
        )

        new_mapping = instance_double(
          Esse::IndexMapping,
          body: {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
            'published' => { 'type' => 'boolean' },
          },
        )
        expect(DummiesIndex::Dummy).to receive(:mapping).and_return(new_mapping)
        expect(DummiesIndex.elasticsearch.update_mapping(type: 'dummy')['acknowledged']).to eq(true)

        mapping = client.indices.get_mapping(index: "#{cluster.index_prefix}_dummies")
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v1", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
            'published' => { 'type' => 'boolean' },
          },
        )
      end
    end

    specify do
      es_client do |client, _conf, cluster|
        expect(DummiesIndex.elasticsearch.create_index(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
        expect(DummiesIndex.elasticsearch.create_index(alias: true, suffix: 'v2')['acknowledged']).to eq(true)
        mapping = client.indices.get_mapping(index: "#{cluster.index_prefix}_dummies*")
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v1", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
          },
        )
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v2", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
          },
        )

        new_mapping = instance_double(
          Esse::IndexMapping,
          body: {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
            'published' => { 'type' => 'boolean' },
          },
        )
        expect(DummiesIndex::Dummy).to receive(:mapping).and_return(new_mapping)
        expect(DummiesIndex.elasticsearch.update_mapping(suffix: 'v1', type: 'dummy')['acknowledged']).to eq(true)

        mapping = client.indices.get_mapping(index: "#{cluster.index_prefix}_dummies*")
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v1", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
            'published' => { 'type' => 'boolean' },
          },
        )
        expect(mapping.dig("#{cluster.index_prefix}_dummies_v2", 'mappings', 'dummy')).to eq(
          'properties' => {
            'title' => { 'type' => 'string', 'index' => 'not_analyzed' },
          },
        )
      end
    end
  end
end
