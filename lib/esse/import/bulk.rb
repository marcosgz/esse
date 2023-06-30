module Esse
  module Import
    class Bulk
      def initialize(index: nil, delete: nil, create: nil)
        @index = Array(index).select(&method(:valid_doc?)).reject(&:ignore_on_index?).map do |doc|
          { index: doc.to_bulk }
        end
        @create = Array(create).select(&method(:valid_doc?)).reject(&:ignore_on_index?).map do |doc|
          { create: doc.to_bulk }
        end
        @delete = Array(delete).select(&method(:valid_doc?)).reject(&:ignore_on_delete?).map do |doc|
          { delete: doc.to_bulk(data: false) }
        end
      end

      # Return an array of RequestBody instances
      #
      # In case of timeout error, will retry with an exponential backoff using the following formula:
      #  wait_interval = (retry_count**4) + 15 + (rand(10) * (retry_count + 1)) seconds. It will retry up to max_retries times that is default 3.
      #
      # Too large bulk requests will be split into multiple requests with only one attempt.
      #
      # @yield [RequestBody] A request body instance
      def each_request(max_retries: 3)
        requests = [optimistic_request]
        retry_count = 0

        begin
          requests.each do |request|
            next unless request.body?
            resp = yield request
            if resp&.[]('errors')
              raise resp&.fetch('items', [])&.select { |item| item.values.first['error'] }&.join("\n")
            end
          end
        rescue Faraday::TimeoutError, Esse::Transport::RequestTimeoutError => e
          retry_count += 1
          raise Esse::Transport::RequestTimeoutError.new(e.message) if retry_count >= max_retries
          wait_interval = (retry_count**4) + 15 + (rand(10) * (retry_count + 1))
          Esse.logger.warn "Timeout error, retrying in #{wait_interval} seconds"
          sleep(wait_interval)
          retry
        rescue Esse::Transport::RequestEntityTooLargeError => e
          retry_count += 1
          raise e if retry_count > 1 # only retry once on this error
          requests = balance_requests_size(e)
          Esse.logger.warn <<~MSG
            Request entity too large, retrying with a bulk with: #{requests.map(&:bytesize).join(' + ')}.
            Note that this cause performance degradation, consider adjusting the batch_size of the index or increasing the bulk size.
          MSG
          retry
        end
      end

      private

      def valid_doc?(doc)
        Esse.document?(doc)
      end

      def optimistic_request
        request = Import::RequestBodyAsJson.new
        request.delete = @delete
        request.create = @create
        request.index = @index
        request
      end

      # @return [Array<RequestBody>]
      def balance_requests_size(err)
        if (bulk_size = err.message.scan(/exceeded.(\d+).bytes/).dig(0, 0).to_i) > 0
          requests = (@delete + @create + @index).each_with_object([Import::RequestBodyRaw.new]) do |as_json, result|
            operation, meta = as_json.to_a.first
            meta = meta.dup
            data = meta.delete(:data)
            piece = MultiJson.dump(operation => meta)
            piece << "\n" << MultiJson.dump(data) if data
            if piece.bytesize > bulk_size
              Esse.logger.warn <<~MSG
                The document #{meta.inspect} size is #{piece.bytesize} bytes, which exceeds the maximum bulk size of #{bulk_size} bytes.
                Consider increasing the bulk size or reducing the document size. The document will be ignored during this import.
              MSG
              next
            end

            if result.last.body.bytesize + piece.bytesize > bulk_size
              result.push(Import::RequestBodyRaw.new.tap { |r| r.add(operation, piece) })
            else
              result[-1].add(operation, piece)
            end
          end
          requests.each(&:finalize)
        else
          raise err
        end
      end
    end
  end
end
