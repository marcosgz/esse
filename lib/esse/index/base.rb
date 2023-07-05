# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      # Sets the client_id associated with the Index class.
      # This can be used directly on Esse::Index to set the :default es cluster
      # to be used by subclasses, or to override the es client used for specific indices:
      #   Esse::Index.cluster_id = :v1
      #   ArtistIndex = Class.new(Esse::Index)
      #   ArtistIndex.cluster_id = :v2
      # @param [Symbol, Esse::Cluster, NilClass] source the cluster id or the cluster instance
      # @return [Symbol] the cluster id
      # @raise [ArgumentError] if the cluster id is not defined in the Esse.config
      def cluster_id=(source)
        if source.nil?
          @cluster_id = nil
          return
        end

        valid_ids = Esse.config.cluster_ids
        new_id = \
          case source
          when Esse::Cluster
            source.id
          when String, Symbol
            id = source.to_sym
            id if valid_ids.include?(id)
          end

        msg = <<~MSG
          We could not resolve the index cluster using the argument %<arg>p. \n
          It must be previously defined in the `Esse.config.cluster(%<arg>p) { ... }' settings. \n
          Here is the list of cluster ids we have configured: %<ids>s\n

          You can ignore this cluster id entirely. That way the :default id will be used.\n
          Example: \n
            class UsersIndex < Esse::Index\n
            end\n
        MSG
        unless new_id
          raise ArgumentError.new, format(msg, arg: source, ids: valid_ids.map(&:inspect).join(', '))
        end

        @cluster_id = new_id
      end

      # @return [Symbol] reads the @cluster_id instance variable or :default
      def cluster_id
        @cluster_id || Config::DEFAULT_CLUSTER_ID
      end

      # @return [Esse::Cluster] an instance of cluster based on its cluster_id
      def cluster
        unless Esse.config.cluster_ids.include?(cluster_id)
          raise NotImplementedError, <<~MSG
            There is no cluster configured for this index. Use `Esse.config.cluster(cluster_id) { ... }' define the elasticsearch
            client connection.
          MSG
        end

        Esse.synchronize { Esse.config.cluster(cluster_id) }
      end

      def inspect
        if self == Index
          super
        elsif abstract_class?
          "#{super}(abstract)"
        elsif index_name?
          "#{super}(Index: #{index_name})"
        else
          "#{super}(Index is not defined)"
        end
      end
    end

    extend ClassMethods
  end
end
