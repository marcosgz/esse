# frozen_string_literal: true

module Esse
  class Index
    module Serializers; end

    module ClassMethods
      # Define a Index method on the given module that calls the Index
      # method on the receiver. This is how the Esse::Index() method is
      # defined, and allows you to define Index() methods on other modules,
      # making it easier to have custom index settings for all indexes under
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

      # Lets you create a Index subclass with its elasticsearch client
      #
      # Example:
      #   # Using a symbol
      #   class UsersIndex < Esse::Index(:v1)
      #     # self.elasticsearch_client == Esse.config.client(:v1)
      #   end
      #
      #   # Using custom elasticsearch client
      #   ES_CLIENT = ::Elasticsearch::Client.new
      #
      #   class UsersIndex < Esse::Index(ES_CLIENT)
      #     # self.elasticsearch_client == ES_CLIENT
      #   end
      def Index(source) # rubocop:disable Naming/MethodName
        klass = Class.new(self)

        klass.elasticsearch_client = \
          if source.is_a?(::Elasticsearch::Client)
            source
          else
            Esse.config.client(source)
          end

        klass.type_hash = {}
        klass
      end

      # Return an instance of Elasticsearch::Client
      def elasticsearch_client
        return @elasticsearch_client if @elasticsearch_client

        @elasticsearch_client = \
          if self == Index
            Esse.synchronize { Esse.config.client }
          else
            superclass.elasticsearch_client
          end
      end

      # Sets the elasticsearch_client associated with the Index class.
      # This can be used directly on Esse::Index to set the default es client
      # to be used by subclasses, or to override the es client used for specific indices:
      #   Esse::Index.elasticsearch_client = CLIENT_V1
      #   ArtistIndex = Class.new(Esse::Index)
      #   ArtistIndex.elasticsearch_client = CLIENT_V2
      def elasticsearch_client=(elasticsearch_client)
        @elasticsearch_client = elasticsearch_client
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
