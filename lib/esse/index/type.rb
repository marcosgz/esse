# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      attr_writer :repo_hash

      def repo_hash
        @repo_hash ||= {}
      end

      def repo(name = nil)
        if name.nil? && repo_hash.size == 1
          name = repo_hash.keys.first
        elsif name.nil? && repo_hash.size > 1
          raise ArgumentError, "You can only call `repo' with a name when there is only one type defined."
        end
        name ||= DEFAULT_REPO_NAME

        repo_hash.fetch(name.to_s)
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
        return repo_hash.size > 0 if name.nil?

        repo_hash.key?(name.to_s)
      end

      def repository(repo_name, *_args, **kwargs, &block)
        repo_class = Class.new(Esse::Repository)
        kwargs[:const] ||= true # TODO Change this to false to avoid collisions with application classes

        if kwargs[:const]
          const_set(Hstring.new(repo_name).camelize.demodulize.to_s, repo_class)
        end

        index = self

        repo_class.send(:define_singleton_method, :index) { index }
        repo_class.send(:define_singleton_method, :repo_name) { repo_name.to_s }
        repo_class.document_type = (kwargs[:document_type] || repo_name).to_s

        plugins.each do |mod|
          next unless mod.const_defined?(:RepositoryClassMethods, false)

          repository_plugin_extend(repo_class, mod::RepositoryClassMethods)
        end

        repo_class.class_eval(&block) if block

        self.repo_hash = repo_hash.merge(repo_class.repo_name => repo_class)
        repo_class
      end
    end

    extend ClassMethods
  end
end
