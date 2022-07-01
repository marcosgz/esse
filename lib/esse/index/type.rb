# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      attr_writer :type_hash

      # @todo rename to repo_hash
      def type_hash 
        @type_hash ||= {}
      end

      def repo(name = nil)
        if name.nil? && type_hash.size == 1
          name = type_hash.keys.first 
        elsif name.nil? && type_hash.size > 1
          raise ArgumentError, "You can only call `repo' with a name when there is only one type defined."
        end
        name ||= DEFAULT_REPO_NAME

        type_hash.fetch(name.to_s)
      rescue KeyError
        raise ArgumentError, <<~MSG
          No repo named "#{name}" found. Use the `repository' method to define one:

            repository :#{name} do
              # collection ...
              # serializer ...
            end
        MSG
      end

      def repo?(name = nil)
        return type_hash.size > 0 if name.nil?

        type_hash.key?(name.to_s)
      end

      def repository(type_name, *_args, **kwargs, &block)
        type_class = Class.new(Esse::IndexType)
        kwargs[:constant] ||= true

        if kwargs[:constant]
          const_set(Hstring.new(type_name).camelize.demodulize.to_s, type_class)
        end

        index = self

        type_class.send(:define_singleton_method, :index) { index }
        type_class.send(:define_singleton_method, :type_name) { type_name.to_s }
        # type_class.send(:define_singleton_method, :repo_name) { type_name.to_s }

        type_class.class_eval(&block) if block

        self.type_hash = type_hash.merge(type_class.type_name => type_class)
        type_class
      end
      alias_method :define_type, :repository
    end

    extend ClassMethods
  end
end
