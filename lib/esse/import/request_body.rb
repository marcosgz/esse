module Esse
  module Import
    class RequestBody
      attr_reader :body, :stats

      def initialize(body:)
        @body = body # body may be String or Array<Hash>
        @stats = { index: 0, create: 0, delete: 0, update: 0 }
      end

      def body?
        !body.empty?
      end
    end

    class RequestBodyRaw < RequestBody
      def initialize
        super(body: '')
      end

      def bytesize
        body.bytesize
      end

      def add(operation, payload)
        stats[operation] += 1
        if @body.empty?
          @body = payload
        else
          @body << "\n" << payload
        end
      end

      def finalize
        @body << "\n"
      end
    end

    class RequestBodyAsJson < RequestBody
      def initialize
        super(body: [])
      end

      def index=(docs)
        @body += docs
        @stats[:index] += docs.size
      end

      def update=(docs)
        @body += docs
        @stats[:update] += docs.size
      end

      def create=(docs)
        @body += docs
        @stats[:create] += docs.size
      end

      def delete=(docs)
        @body += docs
        @stats[:delete] += docs.size
      end
    end
  end
end
