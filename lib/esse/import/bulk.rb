module Esse
  module Import
    class Bulk
      def initialize(index: nil, delete: nil, create: nil, update: nil)
        @index = Esse::ArrayUtils.wrap(index).map { |payload| { index: payload } }
        @create = Esse::ArrayUtils.wrap(create).map { |payload| { create: payload } }
        @update = Esse::ArrayUtils.wrap(update).map { |payload| { update: payload } }
        @delete = Esse::ArrayUtils.wrap(delete).map { |payload| { delete: payload } }
      end

      # Return an array of RequestBody instances
      #
      # In case of timeout error, will retry with an exponential backoff using the following formula:
      #  wait_interval = (retry_count**4) + 15 + (rand(10) * (retry_count + 1)) seconds. It will retry up to max_retries times that is default 4.
      #
      # Too large bulk requests will be split into multiple requests with only one attempt.
      #
      # @yield [RequestBody] A request body instance
      def each_request(max_retries: 4, last_retry_in_small_chunks: true)
        # @TODO create indexes when by checking all the index suffixes (if mapping is not empty)
        requests = [optimistic_request]
        retry_count = 0

        begin
          requests.each do |request|
            next unless request.body?
            resp = yield request
            raise Esse::Transport::BulkResponseError.new(resp) if resp&.[]('errors')
          end
        rescue Faraday::TimeoutError, Esse::Transport::RequestTimeoutError => e
          retry_count += 1
          raise Esse::Transport::RequestTimeoutError.new(e.message) if retry_count >= max_retries
          # Timeout error may be caused by a too large request, so we split the requests in small chunks as a last attempt
          requests = requests_in_small_chunks if last_retry_in_small_chunks && max_retries > 2 && retry_count == max_retries - 2
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

      def optimistic_request
        request = Import::RequestBodyAsJson.new
        request.create = @create
        request.index = @index
        request.update = @update
        request.delete = @delete
        request
      end

      def requests_in_small_chunks(chunk_size: 1)
        arr = []
        @create.each_slice(chunk_size) { |slice| arr << Import::RequestBodyAsJson.new.tap { |r| r.create = slice } }
        @index.each_slice(chunk_size) { |slice| arr << Import::RequestBodyAsJson.new.tap { |r| r.index = slice } }
        @update.each_slice(chunk_size) { |slice| arr << Import::RequestBodyAsJson.new.tap { |r| r.update = slice } }
        @delete.each_slice(chunk_size) { |slice| arr << Import::RequestBodyAsJson.new.tap { |r| r.delete = slice } }
        Esse.logger.warn <<~MSG
          Retrying the last request in small chunks of #{chunk_size} documents.
          This is a last resort to avoid timeout errors, consider increasing the bulk size or reducing the batch size.
        MSG
        arr
      end

      # @return [Array<RequestBody>]
      def balance_requests_size(err)
        if (bulk_size = err.message.scan(/exceeded.(\d+).bytes/).dig(0, 0).to_i) > 0
          requests = (@create + @index + @update + @delete).each_with_object([Import::RequestBodyRaw.new]) do |as_json, result|
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
