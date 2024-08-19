# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Import::Bulk do
  describe '#each_request' do
    let(:index) { [Esse::HashDocument.new(_id: 1, foo: 'bar')] }
    let(:create) { [Esse::HashDocument.new(_id: 2, foo: 'bar')] }
    let(:delete) { [Esse::HashDocument.new(_id: 3, foo: 'bar')] }
    let(:update) { [Esse::HashDocument.new(_id: 4, foo: 'bar')] }
    let(:bulk) { described_class.build_from_documents(index: index, create: create, delete: delete, update: update) }

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
      let(:update) { [] }

      it 'does not yield a request body instance' do
        expect { |b| bulk.each_request(&b) }.not_to yield_control
      end
    end

    context 'when on last retry and last_retry_in_small_chunks is true' do
      let(:index) do
        %w[foo bar baz].each_with_index.map { |name, idx| Esse::HashDocument.new(id: idx + 10, name: name) }
      end
      let(:create) do
        %w[foo bar baz].each_with_index.map { |name, idx| Esse::HashDocument.new(id: idx + 20, name: name) }
      end
      let(:delete) do
        %w[foo bar baz].each_with_index.map { |name, idx| Esse::HashDocument.new(id: idx + 30, name: name) }
      end
      let(:bulk) { described_class.build_from_documents(index: index, create: create, delete: delete) }

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
      let(:index) { [Esse::HashDocument.new(_id: 1, name: 'Aaa' * 30)] }
      let(:create) { [Esse::HashDocument.new(_id: 2, name: 'Bbbb' * 100)] }
      let(:delete) { [Esse::HashDocument.new(_id: 3, name: 'Ccc' * 30)] }
      let(:update) { [Esse::HashDocument.new(_id: 4, name: 'Dddd' * 30)] }

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

        expect(requests[1].body).to eq([
          %[{"create":{"_id":2}}],
          %[{"name":"#{'Bbbb' * 100}"}],
          nil
        ].join("\n"))

        expect(requests[2].body).to eq([
          %[{"index":{"_id":1}}],
          %[{"name":"#{'Aaa' * 30}"}],
          %[{"update":{"_id":4}}],
          %[{"doc":{"name":"#{'Dddd' * 30}"}}],
          %[{"delete":{"_id":3}}],
          nil
        ].join("\n"))
      end

      it 'discards documents that are larger than the bulk size' do
        bulk_size = 200 # 200 bytes
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

        expect(requests[1].body).to eq([
          %[{"index":{"_id":1}}],
          %[{"name":"#{'Aaa' * 30}"}],
          nil
        ].join("\n"))
        expect(requests[2].body).to eq([
          %[{"update":{"_id":4}}],
          %[{"doc":{"name":"#{'Dddd' * 30}"}}],
          %[{"delete":{"_id":3}}],
          nil
        ].join("\n"))
      end
    end
  end
end
