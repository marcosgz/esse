# frozen_string_literal: true

module Esse
  class ClientProxy
    module InstanceMethods
      # Returns results matching a query.
      def search(index:, **options)
        definition = options.merge(
          index: index,
        )

        Esse::Events.instrument('elasticsearch.search') do |payload|
          payload[:request] = definition
          payload[:response] = coerce_exception { client.search(definition) }
        end
      end
    end

    include InstanceMethods
  end
end
