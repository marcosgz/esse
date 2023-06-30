# frozen_string_literal: true

require 'spec_helper'
stack_describe 'elasticsearch', '7.x', 'elasticsearch#scroll' do
  before do
    reset_config!
    stub_index(:geos) do
      repository :country do
        collection do |**, &block|
          block.call [
            { '_id' => 'us', 'name' => 'United States' },
            { '_id' => 'ca', 'name' => 'Canada' }
          ]
        end
        serializer { |geo| Esse::HashDocument.new(geo) }
      end
    end
  end

  describe '.search', events: %w[elasticsearch.search] do
    it 'yields batches of hits' do
      es_client do |client, _conf, cluster|
        GeosIndex.create_index(alias: true)
        GeosIndex.import(refresh: true)

        expect { |b| GeosIndex.search(query: { match_all: {} }).scroll_hits(batch_size: 1, &b) }.to yield_control.twice
      end
    end
  end
end
