# frozen_string_literal: true

module Esse
  module Plugins
    def self.inherited_instance_variables(mod, hash)
      mod.send(:define_method, :inherited_instance_variables) do
        super().merge!(hash)
      end
      mod.send(:private, :inherited_instance_variables)
    end
  end
end
