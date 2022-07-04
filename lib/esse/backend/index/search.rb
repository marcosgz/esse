# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Returns results matching a query.
        def search(suffix: nil, **options)
          definition = options.merge(
            index: index_name(suffix: suffix),
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
end
