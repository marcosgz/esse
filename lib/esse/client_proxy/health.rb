# frozen_string_literal: true

module Esse
  class ClientProxy
    module InstanceMethods
      # Returns basic information about the health of the cluster.
      #
      # @option [List] :index Limit the information returned to a specific index
      # @option [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
      # @option [String] :level Specify the level of detail for returned information (options: cluster, indices, shards)
      # @option [Boolean] :local Return local information, do not retrieve the state from master node (default: false)
      # @option [Time] :master_timeout Explicit operation timeout for connection to master node
      # @option [Time] :timeout Explicit operation timeout
      # @option [String] :wait_for_active_shards Wait until the specified number of shards is active
      # @option [String] :wait_for_nodes Wait until the specified number of nodes is available
      # @option [String] :wait_for_events Wait until all currently queued events with the given priority are processed (options: immediate, urgent, high, normal, low, languid)
      # @option [Boolean] :wait_for_no_relocating_shards Whether to wait until there are no relocating shards in the cluster
      # @option [Boolean] :wait_for_no_initializing_shards Whether to wait until there are no initializing shards in the cluster
      # @option [String] :wait_for_status Wait until cluster is in a specific state (options: green, yellow, red)
      # @option [Hash] :headers Custom HTTP headers
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-health.html
      def health(**options)
        coerce_exception { client.cluster.health(**options) }
      end
    end

    include InstanceMethods
  end
end
