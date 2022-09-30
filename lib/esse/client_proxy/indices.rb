# frozen_string_literal: true

module Esse
  class ClientProxy
    module InstanceMethods
      # Creates an index with optional settings and mappings.
      #
      # @param options [Hash] Options hash
      # @option [String] :index The name of the index
      # @option [String] :wait_for_active_shards Set the number of active shards to wait for before the operation returns.
      # @option [Time] :timeout Explicit operation timeout
      # @option [Time] :master_timeout Specify timeout for connection to master
      # @option [Hash] :headers Custom HTTP headers
      # @option [Hash] :body The configuration for the index (`settings` and `mappings`)
      # @option [String] :wait_for_status Wait until cluster is in a specific state (options: green, yellow, red)
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html
      def create_index(index:, wait_for_status: nil, **options)
        Esse::Events.instrument('elasticsearch.create_index') do |payload|
          payload[:request] = opts = options.merge(**options, index: index)
          payload[:response] = response = coerce_exception { client.indices.create(**opts) }
          coerce_exception do
            cluster.wait_for_status!(status: (wait_for_status || cluster.wait_for_status), index: index)
          end if response && response['acknowledged']

          response
        end
      end
    end

    include InstanceMethods
  end
end
