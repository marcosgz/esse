# frozen_string_literal: true

module Esse
  module Backend
    class Index
      module InstanceMethods
        # Checks the index existance. Returns true or false
        #
        #   UsersIndex.backend.exist? #=> true
        #
        # @param options [Hash] Options hash
        # @option options [String, nil] :suffix The index suffix. Defaults to the index_version.
        #   Use nil if you want to check existence of the `index_name` index or alias.
        def exist?(suffix: index_version)
          name = suffix ? real_index_name(suffix) : index_name
          client.indices.exists(index: name)
        end
      end

      include InstanceMethods
    end
  end
end
