# frozen_string_literal: true

module Esse
  class ClientProxy
    module InstanceMethods
      # Return a list of index aliases.
      #
      # @param options [Hash] Hash of paramenters that will be passed along to elasticsearch request
      # @param options [String] :index A comma-separated list of index names to filter aliases
      # @param options [String] :name A comma-separated list of alias names to return
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.5/indices-get-alias.html
      def aliases(**options)
        coerce_exception { client.indices.get_alias(**options) }
      end
    end

    include InstanceMethods
  end
end
