# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index, '.search' do
  before do
    reset_config!
  end

  describe '#definition' do
    before { stub_index(:events) }

    it 'adds the :body to the definition' do
      expect(EventsIndex.search({ query: {} }).definition).to include(body: { query: {} })
    end

    it 'adds the :q to the definition' do
      expect(EventsIndex.search('foo').definition).to include(q: 'foo')
    end

    it 'converts the :body string to a Hash' do
      expect(EventsIndex.search('{"query": {}}').definition).to include(body: { 'query' => {}})
    end

    it 'keeps the :body Hash as is' do
      expect(EventsIndex.search(body: { query: {}}).definition).to include(body: { query: {} })
    end

    it "merges the 'body' hash to the query definition" do
      expect(EventsIndex.search('body' => { query: { foo: 'bar' } }).definition).to include(body: { query: { foo: 'bar' } })
    end

    it 'keeps the :q string as is' do
      expect(EventsIndex.search(q: 'foo OR bar').definition).to include(q: 'foo OR bar')
    end

    it 'merges the "q" string to the query definition' do
      expect(EventsIndex.search('q' => 'foo').definition).to include(q: 'foo')
    end
  end
end
