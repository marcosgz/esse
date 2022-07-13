# frozen_string_literal: true

require 'spec_helper'
stack_describe 'elasticsearch', '7.x', 'elasticsearch#search' do
  before do
    reset_config!
    stub_index(:geos) do
      repository :country do
        # collection do |**, &block|
        #   block.call [{ '_id' => 'us', 'name' => 'United States' }, { '_id' => 'ca', 'name' => 'Canada' }]
        # end
        # serializer { |geo| geo }
      end
    end
  end

  describe '.search', events: %w[elasticsearch.search] do
    it 'returns a Response' do
      es_client do |client, _conf, cluster|
        GeosIndex.elasticsearch.create_index!(alias: true)

        expect(resp = GeosIndex.elasticsearch.search(body: { query: { match_all: {} } })).to be_an_instance_of(Hash)
        expect(resp).to have_key('hits')
      end
    end
  end
end