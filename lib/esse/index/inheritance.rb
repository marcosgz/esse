# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      # Set this to +true+ if this is an abstract class
      attr_accessor :abstract_class

      def abstract_class?
        return @abstract_class == true if defined?(@abstract_class)

        !index_name?
      end

      def inherited(subclass)
        super

        inherited_instance_variables.each do |variable_name, should_duplicate|
          if (variable_value = instance_variable_get(variable_name)) && should_duplicate
            value = case variable_value
            when Hash
              h = {}
              variable_value.each { |k, v| h[k] = v.dup }
              h
            else
              variable_value.dup
            end
          end
          subclass.instance_variable_set(variable_name, value)
        end
      end

      private

      def inherited_instance_variables
        {
          :@repo_hash => nil,
          :@setting => nil,
          :@mapping => nil,
          :@cluster_id => :dup,
          :@plugins => :dup,
          :@request_params => :dup,
        }
      end
    end

    extend ClassMethods
  end
end
