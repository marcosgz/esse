# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Backend::Index do
  before do
    stub_index(:dummies)
  end

  describe '.reset!' do
    specify do
      es_client do
        expect(DummiesIndex.elasticsearch.reset_index!).to eq(true)
      end
    end

    it 'creates, import data, updates data and delete old indices' do
      es_client do |client, _conf, cluster|
        allow(Esse).to receive(:timestamp).and_return('2020')
        expect(DummiesIndex.elasticsearch.reset_index!(suffix: '2019', refresh: true)).to eq(true)
        expect(DummiesIndex.elasticsearch.indices).to match_array(
          [
            "#{cluster.index_prefix}_dummies_2019",
          ],
        )
        expect(client.indices.get_alias(index: "#{cluster.index_prefix}_dummies")).to eq(
          "#{cluster.index_prefix}_dummies_2019" => {
            'aliases' => {
              "#{cluster.index_prefix}_dummies" => {},
            },
          },
        )

        expect(DummiesIndex.elasticsearch.reset_index!(refresh: true)).to eq(true)
        expect(DummiesIndex.elasticsearch.indices).to match_array(
          [
            "#{cluster.index_prefix}_dummies_2020",
          ],
        )
        expect(client.indices.get_alias(index: "#{cluster.index_prefix}_dummies")).to eq(
          "#{cluster.index_prefix}_dummies_2020" => {
            'aliases' => {
              "#{cluster.index_prefix}_dummies" => {},
            },
          },
        )
      end
    end
  end
end
