# frozen_string_literal: true

require_relative '../primitives'

module Esse
  module CLI
    module EventListener
      extend ColorOutput

      module_function

      def [](event_name)
        method_name = Hstring.new(event_name).underscore.to_sym
        return unless respond_to?(method_name)

        method(method_name)
      end

      def elasticsearch_create_index(event)
        print_success '[%<runtime>s] Index %<name>s successfuly created',
          name: colorize(event[:request][:index], :bold),
          runtime: formatted_runtime(event[:runtime])
      end

      def elasticsearch_delete_index(event)
        print_success '[%<runtime>s] Index %<name>s successfuly deleted',
          name: colorize(event[:request][:index], :bold),
          runtime: formatted_runtime(event[:runtime])
      end

      def elasticsearch_close(event)
        print_success '[%<runtime>s] Index %<name>s successfuly closed',
          name: colorize(event[:request][:index], :bold),
          runtime: formatted_runtime(event[:runtime])
      end

      def elasticsearch_open(event)
        print_success '[%<runtime>s] Index %<name>s successfuly opened',
          name: colorize(event[:request][:index], :bold),
          runtime: formatted_runtime(event[:runtime])
      end

      def elasticsearch_update_mapping(event)
        if event[:request][:type]
          print_success '[%<runtime>s] Index %<name>s mapping for type %<type>s successfuly updated',
            name: colorize(event[:request][:index], :bold),
            type: event[:request][:type],
            runtime: formatted_runtime(event[:runtime])
        else
          print_success '[%<runtime>s] Index %<name>s successfuly updated mapping',
            name: colorize(event[:request][:index], :bold),
            runtime: formatted_runtime(event[:runtime])
        end
      end

      def elasticsearch_update_settings(event)
        print_success '[%<runtime>s] Index %<name>s successfuly updated settings',
          name: colorize(event[:request][:index], :bold),
          runtime: formatted_runtime(event[:runtime])
      end

      def formatted_runtime(number)
        colorize(sprintf('%.3f ms', number), :lightgray)
      end
    end
  end
end
