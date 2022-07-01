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
          extend(mod::ClassMethods) if mod.const_defined?(:ClassMethods, false)
        end

        mod.configure(self, **kwargs, &block) if mod.respond_to?(:configure)
      end

      private

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
