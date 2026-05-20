# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Import::Bulk do
  def build_from_documents(type: nil, index: nil, delete: nil, create: nil, update: nil, index_class: nil)
    index = Array(index).select(&Esse.method(:document?)).reject(&:ignore_on_index?).map do |doc|
      value = doc.to_bulk
      value[:_type] ||= type if type
      value = request_params_for(:index, doc, bulk: true).merge(value) if index_class&.request_params_for?(:index)
      value
    end
    create = Array(create).select(&Esse.method(:document?)).reject(&:ignore_on_index?).map do |doc|
      value = doc.to_bulk
      value[:_type] ||= type if type
      value = request_params_for(:create, doc, bulk: true).merge(value) if index_class&.request_params_for?(:create)
      value
    end
    update = Array(update).select(&Esse.method(:document?)).reject(&:ignore_on_index?).map do |doc|
      value = doc.to_bulk(operation: :update)
      value[:_type] ||= type if type
      value = request_params_for(:update, doc, bulk: true).merge(value) if index_class&.request_params_for?(:update)
      value
    end
    delete = Array(delete).select(&Esse.method(:document?)).reject(&:ignore_on_delete?).map do |doc|
      value = doc.to_bulk(data: false)
      value[:_type] ||= type if type
      value = request_params_for(:delete, doc, bulk: true).merge(value) if index_class&.request_params_for?(:delete)
      value
    end
    Esse::Import::Bulk.new(index: index, delete: delete, create: create, update: update)
  end

  describe '#each_request' do
    let(:index) { [Esse::HashDocument.new(_id: 1, foo: 'bar')] }
    let(:create) { [Esse::HashDocument.new(_id: 2, foo: 'bar')] }
    let(:delete) { [Esse::HashDocument.new(_id: 3, foo: 'bar')] }
    let(:update) { [Esse::HashDocument.new(_id: 4, foo: 'bar')] }
    let(:bulk) { build_from_documents(index: index, create: create, delete: delete, update: update) }

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

    it 'retries on transient server errors and eventually raises' do
      expect(bulk).to receive(:sleep).with(2.0).once
      expect(bulk).to receive(:sleep).with(4.0).once
      expect(Esse.logger).to receive(:warn).with(an_instance_of(String)).twice
      retries = 0
      expect {
        bulk.each_request(retry_on_failure_max_retries: 3, retry_on_failure_wait: 2.0) { |_request|
          retries += 1
          raise Esse::Transport::BadGatewayError
        }
      }.to raise_error(Esse::Transport::BadGatewayError)
      expect(retries).to eq(3)
    end

    it 'retries all transient server error classes' do
      [
        Esse::Transport::BadGatewayError,
        Esse::Transport::ServiceUnavailableError,
        Esse::Transport::GatewayTimeoutError,
        Esse::Transport::TooManyRequestsError,
      ].each do |error_class|
        allow(bulk).to receive(:sleep)
        allow(Esse.logger).to receive(:warn)
        retries = 0
        expect {
          bulk.each_request(retry_on_failure_max_retries: 2, retry_on_failure_wait: 0) { |_request|
            retries += 1
            raise error_class
          }
        }.to raise_error(error_class)
        expect(retries).to eq(2)
      end
    end

    it 'retries on Faraday::ConnectionFailed' do
      allow(bulk).to receive(:sleep)
      allow(Esse.logger).to receive(:warn)
      retries = 0
      expect {
        bulk.each_request(retry_on_failure_max_retries: 2, retry_on_failure_wait: 0) { |_request|
          retries += 1
          raise Faraday::ConnectionFailed, RuntimeError.new('getaddrinfo: Try again')
        }
      }.to raise_error(Faraday::ConnectionFailed)
      expect(retries).to eq(2)
    end

    it 'succeeds when transient error resolves before threshold' do
      allow(bulk).to receive(:sleep)
      allow(Esse.logger).to receive(:warn)
      call_count = 0
      bulk.each_request(retry_on_failure_max_retries: 3, retry_on_failure_wait: 0) { |_request|
        call_count += 1
        raise Esse::Transport::ServiceUnavailableError if call_count == 1
      }
      expect(call_count).to eq(2)
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
      let(:bulk) { build_from_documents(index: index, create: create, delete: delete) }

      it 'retries in small chunks' do
        expect(bulk).to receive(:sleep).with(an_instance_of(Integer)).exactly(3).times
        requests = []
        bulk.each_request(last_retry_in_small_chunks: true) { |request|
          requests << request
          raise Faraday::TimeoutError if [1, 2, 3].include?(requests.size)
        }
        expect(requests.size).to eq(3 + index.size + create.size + delete.size)
      end

      it 'includes document IDs in the timeout per-document retry warning' do
        warnings = []
        allow(Esse.logger).to receive(:warn) { |msg| warnings << msg }
        allow(bulk).to receive(:sleep)
        requests = []
        bulk.each_request(last_retry_in_small_chunks: true) { |request|
          requests << request
          raise Faraday::TimeoutError if requests.size <= 2
        }
        small_chunk_warning = warnings.find { |w| w.include?('one document per request') }
        expect(small_chunk_warning).to include('document IDs:')
        expect(small_chunk_warning).to include('10', '11', '12')
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

      it 'sends documents larger than the bulk size in their own request instead of discarding them' do
        bulk_size = 200 # 200 bytes
        body = elasticsearch_response_fixture(file: 'bulk_request_too_large', version: '7.x', assigns: { request_size: bulk_size })

        requests = []
        bulk.each_request { |request|
          requests << request
          raise Esse::Transport::RequestEntityTooLargeError.new(MultiJson.dump(body)) if requests.size == 1
        }
        expect(requests.size).to eq(4)
        expect(requests[0]).to be_an_instance_of(Esse::Import::RequestBodyAsJson)
        expect(requests[1..]).to all(be_an_instance_of(Esse::Import::RequestBodyRaw))

        bodies = requests[1..].map(&:body)
        expect(bodies).to include([
          %[{"index":{"_id":1}}],
          %[{"name":"#{'Aaa' * 30}"}],
          nil
        ].join("\n"))
        expect(bodies).to include([
          %[{"create":{"_id":2}}],
          %[{"name":"#{'Bbbb' * 100}"}],
          nil
        ].join("\n"))
        expect(bodies).to include([
          %[{"update":{"_id":4}}],
          %[{"doc":{"name":"#{'Dddd' * 30}"}}],
          %[{"delete":{"_id":3}}],
          nil
        ].join("\n"))
      end

      it 'retries one document per request when balanced requests still raise 413' do
        bulk_size = 500
        body = elasticsearch_response_fixture(file: 'bulk_request_too_large', version: '7.x', assigns: { request_size: bulk_size })

        requests = []
        bulk.each_request { |request|
          requests << request
          if requests.size <= 2
            raise Esse::Transport::RequestEntityTooLargeError.new(MultiJson.dump(body))
          end
        }

        # 1 optimistic (413) + 1 first balanced (413, breaks loop) + 4 per-document = 6
        expect(requests.size).to eq(6)
        expect(requests[0]).to be_an_instance_of(Esse::Import::RequestBodyAsJson)
        expect(requests[1]).to be_an_instance_of(Esse::Import::RequestBodyRaw)
        expect(requests[2..]).to all(be_an_instance_of(Esse::Import::RequestBodyAsJson))
        expect(requests[2..].map { |r| r.body.size }).to all(eq(1))
      end

      it 'raises when a single-document bulk still returns 413' do
        bulk_size = 500
        body = elasticsearch_response_fixture(file: 'bulk_request_too_large', version: '7.x', assigns: { request_size: bulk_size })

        expect {
          bulk.each_request { |_request|
            raise Esse::Transport::RequestEntityTooLargeError.new(MultiJson.dump(body))
          }
        }.to raise_error(Esse::Transport::RequestEntityTooLargeError)
      end

      it 'falls through to per-document retry when the 413 message has no parseable size' do
        requests = []
        bulk.each_request { |request|
          requests << request
          raise Esse::Transport::RequestEntityTooLargeError.new('payload too large') if requests.size == 1
        }

        # 1 optimistic + 4 per-document = 5
        expect(requests.size).to eq(5)
        expect(requests[0]).to be_an_instance_of(Esse::Import::RequestBodyAsJson)
        expect(requests[1..]).to all(be_an_instance_of(Esse::Import::RequestBodyAsJson))
        expect(requests[1..].map { |r| r.body.size }).to all(eq(1))
      end

      it 'includes document IDs in the per-document retry warning' do
        warning = nil
        allow(Esse.logger).to receive(:warn) { |msg| warning = msg }
        bulk.each_request { |request|
          raise Esse::Transport::RequestEntityTooLargeError.new('payload too large') if warning.nil?
        }
        expect(warning).to include('document IDs: 2, 1, 4, 3')
      end

      it 'does not retry per-document when last_retry_per_document is false' do
        body = elasticsearch_response_fixture(file: 'bulk_request_too_large', version: '7.x', assigns: { request_size: 500 })

        expect {
          bulk.each_request(last_retry_per_document: false) { |request|
            raise Esse::Transport::RequestEntityTooLargeError.new(MultiJson.dump(body))
          }
        }.to raise_error(Esse::Transport::RequestEntityTooLargeError)
      end
    end
  end
end
