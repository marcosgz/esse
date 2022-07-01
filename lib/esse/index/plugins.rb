# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      attr_reader :plugins

      def plugin(plugin, **kwargs, &block)
        mod = plugin.is_a?(Module) ? plugin : load_plugin_module(plugin)

        unless @plugins.include?(mod)
          @plugins << mod
          mod.apply(self, **kwargs, &block) if mod.respond_to?(:apply)
          extend(mod::IndexClassMethods) if mod.const_defined?(:IndexClassMethods, false)
          if mod.const_defined?(:RepositoryClassMethods, false)
            repo_hash.each_value.each { |repo| repository_plugin_extend(repo, mod::RepositoryClassMethods) }
          end
        end

        mod.configure(self, **kwargs, &block) if mod.respond_to?(:configure)
      end

      private

      def repository_plugin_extend(repo_class, mod)
        return if repo_class.singleton_class.included_modules.include?(mod)

        repo_class.extend(mod)
      end

      def load_plugin_module(name)
        module_name = Hstring.new(name)
        unless Esse::Plugins.const_defined?(module_name.camelize.to_s, false)
          require "esse/plugins/#{module_name.underscore}"
        end
        Esse::Plugins.const_get(module_name.camelize.to_s)
      end
    end

    extend ClassMethods
  end
end
