# frozen_string_literal: true

module Esse
  class Transport
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

      # Returns information about the tasks currently executing on one or more nodes in the cluster.
      #
      # @option arguments [String] :format a short version of the Accept header, e.g. json, yaml
      # @option arguments [List] :nodes A comma-separated list of node IDs or names to limit the returned information; use `_local` to return information from the node you're connecting to, leave empty to get information from all nodes
      # @option arguments [List] :actions A comma-separated list of actions that should be returned. Leave empty to return all.
      # @option arguments [Boolean] :detailed Return detailed task information (default: false)
      # @option arguments [String] :parent_task_id Return tasks with specified parent task id (node_id:task_number). Set to -1 to return all.
      # @option arguments [List] :h Comma-separated list of column names to display
      # @option arguments [Boolean] :help Return help information
      # @option arguments [List] :s Comma-separated list of column names or column aliases to sort by
      # @option arguments [String] :time The unit in which to display time values (options: d, h, m, s, ms, micros, nanos)
      # @option arguments [Boolean] :v Verbose mode. Display column headers
      # @option arguments [Hash] :headers Custom HTTP headers
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/tasks.html
      def tasks(**options)
        # coerce_exception { client.perform_request('GET', '/_tasks', options).body }
        coerce_exception { client.tasks.list(**options) }
      end

      def task(id:, **options)
        coerce_exception { client.tasks.get(task_id: id, **options) }
      end

      def cancel_task(id:, **options)
        coerce_exception { client.tasks.cancel(task_id: id, **options) }
      end
    end

    include InstanceMethods
  end
end
