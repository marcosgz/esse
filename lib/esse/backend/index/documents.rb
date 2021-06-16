# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        def import!(**options)
          type_hash.each_value do |type|
            type.elasticsearch.import!(**options)
          end
        end

        def import(**options)
          type_hash.each_value do |type|
            type.elasticsearch.import(**options)
          end
        end
      end

      include InstanceMethods
    end
  end
end
