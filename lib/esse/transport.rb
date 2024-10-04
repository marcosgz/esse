# frozen_string_literal: true

module Esse
  class Transport
    require_relative './transport/aliases'
    require_relative './transport/cluster'
    require_relative './transport/indices'
    require_relative './transport/search'
    require_relative './transport/documents'

    extend Forwardable

    def_delegators :@cluster, :client, :throw_error_when_readonly!

    attr_reader :cluster

    def initialize(cluster)
      @cluster = cluster
    end

    # Elasticsearch::Transport was renamed to Elastic::Transport in 8.0
    # This lib should support both versions that's why we are wrapping up the transport
    # errors to local errors.
    #
    # We are not only coercing exceptions but also the response body. Elasticsearch-ruby >= 8.0 returns
    # the response wrapped in a Elasticsearch::API::Response::Response object. We are unwrapping it
    # to keep the same interface. But we may want to coerce it to some internal object in the future.
    def coerce_exception
      resp = yield
      if resp.class.name.start_with?('Elasticsearch::API::Response')
        resp = resp.body
      end
      resp
    rescue => exception
      name = Hstring.new(exception.class.name)
      if /^(Elasticsearch|Elastic|OpenSearch)?::Transport::Transport::Errors/.match?(name.value) && \
          (exception_class = Esse::Transport::ERRORS[name.demodulize.value])
        raise exception_class.new(exception.message)
      else
        raise exception
      end
    end
  end
end
