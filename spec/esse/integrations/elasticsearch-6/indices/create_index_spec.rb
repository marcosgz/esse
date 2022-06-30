# frozen_string_literal: true

require 'spec_helper'

stack_describe '7.x', 'elasticsearch create index' do
  describe '.create!' do
    context 'without settings and mappings' do
      before do
        stub_index(:dummies)
      end

      specify do
        es_client do
          expect(DummiesIndex.elasticsearch.create_index['acknowledged']).to eq(true)
        end
      end

      it 'creates a suffixed index and its alias' do
        es_client do |client, _conf, cluster|
          allow(Esse).to receive(:timestamp).and_return('2020')
          expect(DummiesIndex.elasticsearch.create_index!['acknowledged']).to eq(true)
          expect(DummiesIndex.elasticsearch.create_index!(suffix: 'v1')['acknowledged']).to eq(true)
          expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(true)
          expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
          expect { DummiesIndex.elasticsearch.create_index!(suffix: 'v1') }.to raise_error(
            Esse::Backend::BadRequestError,
          ).with_message(/already exists/)
          expect(DummiesIndex.elasticsearch.indices).to match_array(
            [
              "#{cluster.index_prefix}_dummies_2020",
              "#{cluster.index_prefix}_dummies_v1"
            ],
          )
          expect(DummiesIndex.elasticsearch.aliases).to match_array(
            [
              "#{cluster.index_prefix}_dummies"
            ],
          )
        end
      end

      it 'creates a suffixed index without alias' do
        es_client do |client, _conf, cluster|
          allow(Esse).to receive(:timestamp).and_return('2020')
          expect(DummiesIndex.elasticsearch.create_index!(alias: false)['acknowledged']).to eq(true)
          expect(DummiesIndex.elasticsearch.create_index!(alias: false, suffix: 'v1')['acknowledged']).to eq(true)
          expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies")).to eq(false)
          expect(client.indices.exists(index: "#{cluster.index_prefix}_dummies_v1")).to eq(true)
          expect { DummiesIndex.elasticsearch.create_index!(alias: false, suffix: 'v1') }.to raise_error(
            Esse::Backend::BadRequestError,
          ).with_message(/already exists/)
          expect(DummiesIndex.elasticsearch.indices).to match_array([])
          expect(DummiesIndex.elasticsearch.aliases).to eq([])
        end
      end
    end

    context 'with settings and mappings' do
      before do
        stub_index(:dummies) do
          settings do
            {
              number_of_shards: 2,
            }
          end
          define_type :dummy do
            mappings do
              {
                age: { type: 'integer' },
              }
            end
          end
        end
      end

      it 'creates index with settings and mappings' do
        es_client do |client, _conf, cluster|
          expect(DummiesIndex.elasticsearch.create_index!(alias: true, suffix: 'v1')['acknowledged']).to eq(true)
          real_name = "#{DummiesIndex.index_name}_v1"
          response = client.indices.get_mapping(index: real_name)
          expect(response.dig(real_name, 'mappings', 'properties')).to eq('age' => { 'type' => 'integer' })
          response = client.indices.get_settings(index: real_name)
          expect(response.dig(real_name, 'settings', 'index', 'number_of_shards')).to eq('2')
        end
      end
    end
  end
end
