# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Checks the index existance. Returns true or false
        #
        #   UsersIndex.elasticsearch.exist? #=> true
        #
        # @param options [Hash] Options hash
        # @option options [String, nil] :suffix The index suffix. Defaults to the index_version.
        #   Use nil if you want to check existence of the `index_name` index or alias.
        def exist?(suffix: index_version)
          coerce_exception { client.indices.exists(index: index_name(suffix: suffix)) }
        end
      end

      include InstanceMethods
    end
  end
end
