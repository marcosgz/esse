# frozen_string_literal: true

module Esse
  class Transport
    module InstanceMethods
      # Return a list of index aliases.
      #
      # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
      # @option [String] :index A comma-separated list of index names to filter aliases
      # @option [String] :name A comma-separated list of alias names to return
      # @raise [Esse::Transport::ServerError] in case of failure
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/indices-get-alias.html
      def aliases(**options)
        coerce_exception { client.indices.get_alias(**options) }
      end

      # Updates index aliases.
      #
      # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
      # @option [Hash] :body The definition of `actions` to perform
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-aliases.html
      def update_aliases(body:, **options)
        Esse::Events.instrument('elasticsearch.update_aliases') do |payload|
          payload[:request] = options
          payload[:response] = coerce_exception { client.indices.update_aliases(**options, body: body) }
        end
      end
    end

    include InstanceMethods
  end
end
