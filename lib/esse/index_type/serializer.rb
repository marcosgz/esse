# frozen_string_literal: true

module Esse
  class IndexType
    module ClassMethods
      # Convert ruby object to json. Arguments will be same of passed through the
      # collection. It's allowed a block or a class with the `as_json` instance method.
      # Example with block
      #   serializer do |model, context = {}|
      #     {
      #       id: model.id,
      #       admin: context[:is_admin],
      #     }
      #   end
      # Example with serializer class
      #   serializer UserSerializer
      def serializer(klass = nil, &block)
        if block_given?
          @serializer_proc = block
        elsif klass.is_a?(Class) && klass.instance_methods.include?(:as_json)
          @serializer_proc = proc { |*args| klass.new(*args).as_json }
        elsif klass.is_a?(Class) && klass.instance_methods.include?(:call)
          @serializer_proc = proc { |*args| klass.new(*args).call }
        else
          raise ArgumentError, format('%<arg>p is not a valid serializer. The serializer should ' \
                                      'respond with `as_json` instance method.', arg: klass,)
        end
      end

      def serialize(model, *args)
        unless @serializer_proc
          raise NotImplementedError, format('there is no serializer defined for the %<k>p index', k: to_s)
        end

        @serializer_proc.call(model, *args)
      end

      # Used to define the source of data. A block is required. And its
      # content should yield an array of each object that should be serialized.
      # The list of arguments will be passed throught the serializer method.
      #
      # Here is an example of how this should work:
      #   collection do |conditions, &block|
      #     User.where(conditions).find_in_batches(batch_size: 5000) do |batch|
      #       block.call(batch, conditions)
      #     end
      #   end
      def collection(&block)
        raise(SyntaxError, 'No block given') unless block_given?

        @collection_proc = block
      end

      # Used to fetch all batch of data defined on the collection model.
      # Arguments can be anything. They will just be passed through the block.
      # Useful when the collection depends on scope or any other conditions
      # Example
      #   each_batch(active: true) do |data, _opts|
      #     puts data.size
      #   end
      def each_batch(*args, &block)
        unless @collection_proc
          raise NotImplementedError, format('there is no collection defined for the %<k>p index', k: to_s)
        end

        @collection_proc.call(*args, &block)
      rescue LocalJumpError
        raise(SyntaxError, 'block must be explicitly declared in the collection definition')
      end

      # Wrap collection data into serialized batches
      #
      # @param [*Object] Any argument is allowed here. The collection will be called with same arguments.
      #   And the serializer will be initialized with those arguments too.
      # @yield [Array, *Object] serialized collection and method arguments
      def each_serialized_batch(*args, &block)
        each_batch(*args) do |batch, *serializer_args|
          entries = batch.map { |entry| serialize(entry, *serializer_args) }.compact
          block.call(entries, *args)
        end
      end
    end

    extend ClassMethods
  end
end
