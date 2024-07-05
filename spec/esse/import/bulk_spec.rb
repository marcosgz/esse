# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Import::Bulk do
  describe '#each_request' do
    let(:index) { [Esse::HashDocument.new(id: 1, source: { foo: 'bar' })] }
    let(:create) { [Esse::HashDocument.new(id: 2, source: { foo: 'bar' })] }
    let(:delete) { [Esse::HashDocument.new(id: 3, source: { foo: 'bar' })] }
    let(:bulk) { described_class.new(index: index, create: create, delete: delete) }

    it 'yields a request body instance' do
      expect { |b| bulk.each_request(&b) }.to yield_with_args(Esse::Import::RequestBodyAsJson)
    end

    it 'retries on Faraday::TimeoutError' do
      expect(bulk).to receive(:sleep).with(an_instance_of(Integer)).twice
      expect(Esse.logger).to receive(:warn).with(an_instance_of(String)).twice
      retries = 0
      expect {
        bulk.each_request(max_retries: 3, last_retry_in_small_chunks: false) { |request|
          retries += 1
          raise Faraday::TimeoutError
        }
      }.to raise_error(Esse::Transport::RequestTimeoutError)
      expect(retries).to eq(3)
    end

    it 'retries on Esse::Transport::RequestTimeoutError' do
      expect(bulk).to receive(:sleep).with(an_instance_of(Integer)).twice
      expect(Esse.logger).to receive(:warn).with(an_instance_of(String)).twice
      retries = 0
      expect {
        bulk.each_request(max_retries: 3, last_retry_in_small_chunks: false) { |request|
          retries += 1
          raise Esse::Transport::RequestTimeoutError
        }
      }.to raise_error(Esse::Transport::RequestTimeoutError)
      expect(retries).to eq(3)
    end

    context 'without data' do
      let(:index) { [] }
      let(:create) { [] }
      let(:delete) { [] }

      it 'does not yield a request body instance' do
        expect { |b| bulk.each_request(&b) }.not_to yield_control
      end
    end

    context 'when on last retry and last_retry_in_small_chunks is true' do
      let(:index) do
        %w[foo bar baz].each_with_index.map { |name, idx| Esse::HashDocument.new(id: idx + 10, source: { name: name }) }
      end
      let(:create) do
        %w[foo bar baz].each_with_index.map { |name, idx| Esse::HashDocument.new(id: idx + 20, source: { name: name }) }
      end
      let(:delete) do
        %w[foo bar baz].each_with_index.map { |name, idx| Esse::HashDocument.new(id: idx + 30, source: { name: name }) }
      end
      let(:bulk) { described_class.new(index: index, create: create, delete: delete) }

      it 'retries in small chunks' do
        expect(bulk).to receive(:sleep).with(an_instance_of(Integer)).exactly(3).times
        requests = []
        bulk.each_request(last_retry_in_small_chunks: true) { |request|
          requests << request
          raise Faraday::TimeoutError if [1, 2, 3].include?(requests.size)
        }
        expect(requests.size).to eq(3 + index.size + create.size + delete.size)
      end
    end

    context 'with a request entity too large error' do
      let(:index) { [Esse::HashDocument.new(id: 1, source: { name: 'Aaa' * 30 })] }
      let(:create) { [Esse::HashDocument.new(id: 2, source: { name: 'Bbbb' * 100 })] }
      let(:delete) { [Esse::HashDocument.new(id: 3, source: { name: 'Ccc' * 30 })] }

      it 'adjusts body into multiple requests on Esse::Transport::RequestEntityTooLargeError' do
        bulk_size = 500 # 500 bytes
        body = elasticsearch_response_fixture(file: 'bulk_request_too_large', version: '7.x', assigns: { request_size: bulk_size })

        requests = []
        bulk.each_request { |request|
          requests << request
          raise Esse::Transport::RequestEntityTooLargeError.new(MultiJson.dump(body)) if requests.size == 1
        }
        expect(requests.size).to eq(3)
        expect(requests[0]).to be_an_instance_of(Esse::Import::RequestBodyAsJson)
        expect(requests[1]).to be_an_instance_of(Esse::Import::RequestBodyRaw)
        expect(requests[2]).to be_an_instance_of(Esse::Import::RequestBodyRaw)

        expect(requests[1].body).to eq(
          "{\"delete\":{\"_id\":3}}\n{\"create\":{\"_id\":2}}\n{\"id\":2,\"source\":{\"name\":\"#{'Bbbb' * 100}\"}}\n"
        )
        expect(requests[2].body).to eq(
          "{\"index\":{\"_id\":1}}\n{\"id\":1,\"source\":{\"name\":\"#{'Aaa' * 30}\"}}\n"
        )
      end

      it 'discard documents that are larger than the bulk size' do
        bulk_size = 150 # 200 bytes
        body = elasticsearch_response_fixture(file: 'bulk_request_too_large', version: '7.x', assigns: { request_size: bulk_size })

        requests = []
        bulk.each_request { |request|
          requests << request
          raise Esse::Transport::RequestEntityTooLargeError.new(MultiJson.dump(body)) if requests.size == 1
        }
        expect(requests.size).to eq(3)
        expect(requests[0]).to be_an_instance_of(Esse::Import::RequestBodyAsJson)
        expect(requests[1]).to be_an_instance_of(Esse::Import::RequestBodyRaw)
        expect(requests[2]).to be_an_instance_of(Esse::Import::RequestBodyRaw)

        expect(requests[1].body).to eq(
          "{\"delete\":{\"_id\":3}}\n"
        )
        expect(requests[2].body).to eq(
          "{\"index\":{\"_id\":1}}\n{\"id\":1,\"source\":{\"name\":\"#{'Aaa' * 30}\"}}\n"
        )
      end
    end
  end
end
