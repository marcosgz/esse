# frozen_string_literal: true

module Esse
  class ClientProxy
    require_relative './client_proxy/search'

    extend Forwardable

    def_delegators :@cluster, :client

    attr_reader :cluster

    def initialize(cluster)
      @cluster = cluster
    end

    # Elasticsearch::Transport was renamed to Elastic::Transport in 8.0
    # This lib should support both versions that's why we are wrapping up the transport
    # errors to local errors.
    def coerce_exception
      yield
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
