# frozen_string_literal: true

module Esse
  module ObjectDocumentMapper
    # Convert ruby object to json. Arguments will be same of passed through the
    # collection. It's allowed a block or a class with the `to_h` instance method.
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
      if block
        @serializer_proc = block
      elsif klass.is_a?(Class) && klass.instance_methods.include?(:to_h)
        @serializer_proc = proc { |*args| klass.new(*args).to_h }
      elsif klass.is_a?(Class) && klass.instance_methods.include?(:as_json) # backward compatibility
        @serializer_proc = proc { |*args| klass.new(*args).as_json }
      elsif klass.is_a?(Class) && klass.instance_methods.include?(:call)
        @serializer_proc = proc { |*args| klass.new(*args).call }
      else
        msg = format('%<arg>p is not a valid serializer. The serializer should ' \
                      'respond with `to_h` instance method.', arg: klass,)
        raise ArgumentError, msg
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
    def collection(collection_class = nil, &block)
      raise ArgumentError, 'a collection class or a block is required' if block.nil? && collection_class.nil?

      if block.nil? && collection_class.is_a?(Class) && !collection_class.include?(Enumerable)
        msg = '%<arg>p is not a valid collection class.' \
              ' Collections should implement the Enumerable interface'
        raise ArgumentError, format(msg, arg: collection_class)
      end

      @collection_proc = collection_class || block
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

      case @collection_proc
      when Class
        @collection_proc.new(*args).each(&block)
      else
        @collection_proc.call(*args, &block)
      end
    rescue LocalJumpError
      raise(SyntaxError, 'block must be explicitly declared in the collection definition')
    end

    # Wrap collection data into serialized batches
    #
    # @param args [*Object] Any argument is allowed here. The collection will be called with same arguments.
    #   And the serializer will be initialized with those arguments too.
    # @yield [Array, *Object] serialized collection and method arguments
    def each_serialized_batch(*args, &block)
      each_batch(*args) do |batch|
        entries = batch.map { |entry| serialize(entry, *args) }.compact
        block.call(entries, *args)
      end
    end
  end
end
