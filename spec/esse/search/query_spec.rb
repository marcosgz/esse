# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Search::Query do
  describe '.normalize_indices' do
    context 'when the argument is a string' do
      it 'returns a string with names' do
        expect(described_class.normalize_indices('events')).to eq('events')
        expect(described_class.normalize_indices('events', 'venues')).to eq('events,venues')
      end
    end

    context 'when the argument is a symbol' do
      it 'returns a string with names' do
        expect(described_class.normalize_indices(:events)).to eq('events')
        expect(described_class.normalize_indices(:events, :venues)).to eq('events,venues')
      end
    end

    context 'when the argument is Esse::Index' do
      before do
        stub_index(:events)
        stub_index(:venues)
      end
      it 'returns a string with names' do
        expect(described_class.normalize_indices(EventsIndex)).to eq('events')
        expect(described_class.normalize_indices(EventsIndex, VenuesIndex)).to eq('events,venues')
      end
    end
  end

  describe '#definition' do
    before do
      stub_index(:events)
      stub_index(:venues)
    end

    it 'builds a valid request parameters with a single index class' do
      expect(
        Esse::Search::Query.new(
          EventsIndex.cluster.api,
          EventsIndex,
          q: '*',
          timeout: '1m'
        ).definition
      ).to include(index: EventsIndex.index_name, q: '*', timeout: '1m')
    end

    it 'builds a valid request parameters with a single index name' do
      expect(
        Esse::Search::Query.new(
          EventsIndex.cluster.api,
          'events',
          q: '*',
          timeout: '1m'
        ).definition
      ).to include(index: 'events', q: '*', timeout: '1m')
    end

    it 'builds a valid request parameters with multiple index classes' do
      expect(
        Esse::Search::Query.new(
          EventsIndex.cluster.api,
          EventsIndex,
          VenuesIndex,
          q: '*',
          timeout: '1m'
        ).definition
      ).to include(index: [EventsIndex.index_name, VenuesIndex.index_name].join(','), q: '*', timeout: '1m')
    end

    it 'builds a valid request parameters with multiple index names' do
      expect(
        Esse::Search::Query.new(
          EventsIndex.cluster.api,
          'events',
          'venues',
          q: '*',
          timeout: '1m'
        ).definition
      ).to include(index: ['events', 'venues'].join(','), q: '*', timeout: '1m')
    end

    it 'adds the suffix to the index name' do
      expect(
        Esse::Search::Query.new(
          EventsIndex.cluster.api,
          'events',
          VenuesIndex,
          suffix: '2022',
          q: '*',
          timeout: '1m'
        ).definition
      ).to include(index: "events_2022,#{VenuesIndex.index_name(suffix: '2022')}", q: '*', timeout: '1m')
    end
  end

  describe '#response' do
    let(:transport) { instance_double(Esse::Transport) }
    let(:request_body) { { query: { match_all: {} } } }
    let(:query) { described_class.new(transport, 'events', body: request_body) }

    it 'returns a Response' do
      body = elasticsearch_response_fixture(file: 'search_result_empty', version: '7.x', assigns: { index_name: 'geos' })

      expect(transport).to receive(:search).with(index: 'events', body: request_body).and_return(body)

      expect(resp = query.response).to be_an_instance_of(Esse::Search::Response)
      expect(resp.query).to eq(query)
    end
  end

  describe '#execute_search_query!', events: %w[elasticsearch.execute_search_query] do
    let(:transport) { instance_double(Esse::Transport) }
    let(:request_body) { { query: { match_all: {} } } }
    let(:query) { described_class.new(transport, 'events', body: request_body) }

    before { stub_index(:events) }

    context 'when the query is successful' do
      it 'returns a Response' do
        response_body = elasticsearch_response_fixture(file: 'search_result_empty', version: '7.x', assigns: { index_name: 'geos' })
        expect(transport).to receive(:search).with(index: 'events', body: request_body).and_return(response_body)

        expect(query.response).to be_an_instance_of(Esse::Search::Response)
        assert_event 'elasticsearch.execute_search_query', { query: query, response: query.response }
      end
    end

    context 'when the query fails' do
      let(:request_body) { { query: { match_all: {} }, size: 0 } }

      it 'raises an exception' do
        exception = Esse::Transport::BadRequestError.new
        expect(transport).to receive(:search).with(index: 'events', body: request_body).and_raise(exception)

        expect {
          query.response
        }.to raise_error(Esse::Transport::BadRequestError)
        assert_event 'elasticsearch.execute_search_query', { query: query, error: exception }
      end
    end
  end

  describe '#results' do
    let(:transport) { instance_double(Esse::Transport) }
    let(:request_body) { { query: { match_all: {} } } }
    let(:query) { described_class.new(transport, EventsIndex, body: request_body) }

    before { stub_index(:events) }

    context 'with elasticsearch < 7.x' do
      let(:response_document) do
        {
          'took' => '5', 'timed_out' => false, '_shards' => {'one' => 'OK'},
          'hits' => { 'total' => 100, 'hits' => (1..100).to_a.map { |i| { _id: i } } }
        }
      end

      it 'returns the hits' do
        expect(transport).to receive(:search).with(index: EventsIndex.index_name, body: request_body).and_return(response_document)

        expect(query.results).to be_an_instance_of(Array)
        expect(query.results.size).to eq(100)
      end
    end

    context 'with elasticsearch >= 7.x' do
      let(:response_document) do
        {
          'took' => '5', 'timed_out' => false, '_shards' => {'one' => 'OK'},
          'hits' => { 'total' => { 'value' => 100, 'relation' => 'eq' }, 'hits' => (1..100).to_a.map { |i| { _id: i } } }
        }
      end

      it 'returns the hits and aggregations' do
        expect(transport).to receive(:search).with(index: EventsIndex.index_name, body: request_body).and_return(response_document)

        expect(query.results).to be_an_instance_of(Array)
        expect(query.results.size).to eq(100)
      end
    end

    context 'when query have the :paginated_results method' do
      it 'returns the data from paginated_results instead' do
        query.extend Module.new {
                       def paginated_results
                         [:ok]
                       end
                     }

        expect(query.results).to eq([:ok])
      end
    end
  end

  describe '#raw_limit_value' do
    subject { described_class.new(Class.new(Esse::Index), **params).send(:raw_limit_value) }

    let(:params) { {} }

    it { is_expected.to eq(nil) }

    context 'when definition have [:body][:size] value' do
      let(:params) do
        {
          body: {
            size: 10
          }
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when definition have [:body]["size"] value' do
      let(:params) do
        {
          body: {
            'size' => 10
          }
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when params have the :size' do
      let(:params) { { size: 20 } }

      it { is_expected.to eq(20) }
    end
  end

  describe '#raw_offset_value' do
    subject { described_class.new(Class.new(Esse::Index), **params).send(:raw_offset_value) }

    let(:params) { {} }

    it { is_expected.to eq(nil) }

    context 'when definition have [:body][:from] value' do
      let(:params) do
        {
          body: {
            from: 10
          }
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when definition have [:body]["from"] value' do
      let(:params) do
        {
          body: {
            'from' => 10
          }
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when params have the :from' do
      let(:params) { { from: 20 } }

      it { is_expected.to eq(20) }
    end
  end

  describe '#search_after_hits', events: %w[elasticsearch.execute_search_query] do
    let(:transport) { instance_double(Esse::Transport) }

    def build_response(hits)
      {
        'took' => 5, 'timed_out' => false, '_shards' => { 'total' => 1, 'successful' => 1, 'skipped' => 0, 'failed' => 0 },
        'hits' => {
          'total' => { 'value' => hits.size, 'relation' => 'eq' },
          'hits' => hits
        }
      }
    end

    it 'raises ArgumentError when no sort is present in the body' do
      query = described_class.new(transport, 'events', body: { query: { match_all: {} } })

      expect {
        query.search_after_hits { |_hits| }
      }.to raise_error(ArgumentError, /must include a :sort/)
    end

    it 'raises ArgumentError when body is empty' do
      query = described_class.new(transport, 'events', body: {})

      expect {
        query.search_after_hits { |_hits| }
      }.to raise_error(ArgumentError, /must include a :sort/)
    end

    it 'yields batches of hits across multiple pages' do
      query = described_class.new(transport, 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }] })
      page1_hits = [{ '_id' => '1', 'sort' => [1] }, { '_id' => '2', 'sort' => [2] }]
      page2_hits = [{ '_id' => '3', 'sort' => [3] }]

      expect(transport).to receive(:search)
        .with(index: 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }], size: 2 })
        .and_return(build_response(page1_hits))
      expect(transport).to receive(:search)
        .with(index: 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }], size: 2, search_after: [2] })
        .and_return(build_response(page2_hits))

      batches = []
      query.search_after_hits(batch_size: 2) { |hits| batches << hits }
      expect(batches).to eq([page1_hits, page2_hits])
    end

    it 'stops when response returns empty hits' do
      query = described_class.new(transport, 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }] })

      expect(transport).to receive(:search)
        .with(index: 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }], size: 1_000 })
        .and_return(build_response([]))

      batches = []
      query.search_after_hits { |hits| batches << hits }
      expect(batches).to be_empty
    end

    it 'stops when last page has fewer hits than batch_size' do
      query = described_class.new(transport, 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }] })
      page_hits = [{ '_id' => '1', 'sort' => [1] }]

      expect(transport).to receive(:search)
        .with(index: 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }], size: 5 })
        .once
        .and_return(build_response(page_hits))

      batches = []
      query.search_after_hits(batch_size: 5) { |hits| batches << hits }
      expect(batches).to eq([page_hits])
    end

    it 'strips :from from body' do
      query = described_class.new(transport, 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }], from: 10 })

      expect(transport).to receive(:search)
        .with(index: 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }], size: 1_000 })
        .and_return(build_response([]))

      query.search_after_hits { |_hits| }
    end

    it 'strips string-keyed "from" from body' do
      query = described_class.new(transport, 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }], 'from' => 10 })

      expect(transport).to receive(:search)
        .with(index: 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }], size: 1_000 })
        .and_return(build_response([]))

      query.search_after_hits { |_hits| }
    end

    it 'works with string-keyed sort in body' do
      query = described_class.new(transport, 'events', body: { query: { match_all: {} }, 'sort' => [{ 'id' => 'asc' }] })

      expect(transport).to receive(:search)
        .with(index: 'events', body: { query: { match_all: {} }, 'sort' => [{ 'id' => 'asc' }], size: 1_000 })
        .and_return(build_response([]))

      query.search_after_hits { |_hits| }
    end

    it 'stops when last hit has no sort values' do
      query = described_class.new(transport, 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }] })
      page_hits = [{ '_id' => '1' }]

      expect(transport).to receive(:search)
        .with(index: 'events', body: { query: { match_all: {} }, sort: [{ id: :asc }], size: 1 })
        .once
        .and_return(build_response(page_hits))

      batches = []
      query.search_after_hits(batch_size: 1) { |hits| batches << hits }
      expect(batches).to eq([page_hits])
    end

    it 'does not mutate the original definition body' do
      original_body = { query: { match_all: {} }, sort: [{ id: :asc }], from: 10 }
      query = described_class.new(transport, 'events', body: original_body)

      expect(transport).to receive(:search).and_return(build_response([]))

      query.search_after_hits { |_hits| }
      expect(original_body).to eq(query: { match_all: {} }, sort: [{ id: :asc }], from: 10)
    end
  end
end
