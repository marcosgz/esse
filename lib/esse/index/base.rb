# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      attr_reader :cluster_id

      # Define a Index method on the given module that calls the Index
      # method on the receiver. This is how the Esse::Index() method is
      # defined, and allows you to define Index() methods on other modules,
      # making it easier to have custom index settings for all indices under
      # a namespace.  Example:
      #
      #   module V1
      #     EsIndex = Class.new(Esse::Index)
      #     EsIndex.def_Index(self)
      #
      #     class Bar < EsIndex
      #       # Uses :default elasticsearch client connection
      #     end
      #
      #     class Baz < EsIndex(:v1)
      #       # Uses :v1 elasticsearch client connection
      #     end
      #   end
      def def_Index(index_module) # rubocop:disable Naming/MethodName
        tap do |model|
          index_module.define_singleton_method(:Index) do |source|
            model.Index(source)
          end
        end
      end

      # Lets you create a Index subclass with its elasticsearch cluster
      #
      # Example:
      #   # Using a custom cluster
      #   Esse.config.clusters(:v1).client = Elasticsearch::Client.new
      #   class UsersIndex < Esse::Index(:v1)
      #   end
      #
      #   # Using :default cluster
      #   class UsersIndex < Esse::Index
      #   end
      def Index(source) # rubocop:disable Naming/MethodName
        klass = Class.new(self)

        valid_ids = Esse.config.cluster_ids
        klass.cluster_id = \
          case source
          when Esse::Cluster
            source.id
          when String, Symbol
            id = source.to_sym
            id if valid_ids.include?(id)
          end

        msg = <<~MSG
          We could not resolve the index cluster using the argument %<arg>p. \n
          It must be previously defined in the `Esse.config' settings. \n
          Here is the list of cluster ids we have configured: %<ids>s\n

          You can ignore this cluster id entirely. That way the :default id will be used.\n
          Example: \n
            class UsersIndex < Esse::Index\n
            end\n
        MSG
        unless klass.cluster_id
          raise ArgumentError.new, format(msg, arg: source, ids: valid_ids.map(&:inspect).join(', '))
        end

        klass.type_hash = {}
        klass
      end

      # Sets the client_id associated with the Index class.
      # This can be used directly on Esse::Index to set the :default es cluster
      # to be used by subclasses, or to override the es client used for specific indices:
      #   Esse::Index.cluster_id = :v1
      #   ArtistIndex = Class.new(Esse::Index)
      #   ArtistIndex.cluster_id = :v2
      def cluster_id=(cluster_id)
        @cluster_id = cluster_id
      end

      # @return [Symbol] reads the @cluster_id instance variable or :default
      def cluster_id
        @cluster_id || Config::DEFAULT_CLUSTER_ID
      end

      # @return [Esse::Cluster] an instance of cluster based on its cluster_id
      def cluster
        unless Esse.config.cluster_ids.include?(cluster_id)
          raise NotImplementedError, <<~MSG
            There is no cluster configured for this index. Use `Esse.config.clusters(cluster_id) { ... }' define the elasticsearch
            client connection.
          MSG
        end

        Esse.synchronize { Esse.config.clusters(cluster_id) }
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
