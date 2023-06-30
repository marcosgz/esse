# frozen_string_literal: true

require_relative '../primitives'

module Esse
  module CLI
    module EventListener
      extend Output

      module_function

      def [](event_name)
        method_name = Hstring.new(event_name).underscore.to_sym
        return unless respond_to?(method_name)

        method(method_name)
      end

      def elasticsearch_create_index(event)
        print_message '[%<runtime>s] Index %<name>s successfuly created',
          name: colorize(event[:request][:index], :bold),
          runtime: formatted_runtime(event[:runtime])
        if (aliases = event.to_h.dig(:request, :body, :aliases)).is_a?(Hash)
          print_message ' --> Aliases: %<aliases>s', aliases: aliases.keys.join(', ')
        end
      end

      def elasticsearch_delete_index(event)
        print_message '[%<runtime>s] Index %<name>s successfuly deleted',
          name: colorize(event[:request][:index], :bold),
          runtime: formatted_runtime(event[:runtime])
      end

      def elasticsearch_close(event)
        print_message '[%<runtime>s] Index %<name>s successfuly closed',
          name: colorize(event[:request][:index], :bold),
          runtime: formatted_runtime(event[:runtime])
      end

      def elasticsearch_open(event)
        print_message '[%<runtime>s] Index %<name>s successfuly opened',
          name: colorize(event[:request][:index], :bold),
          runtime: formatted_runtime(event[:runtime])
      end

      def elasticsearch_update_mapping(event)
        if event[:request][:type]
          print_message '[%<runtime>s] Index %<name>s mapping for type %<type>s successfuly updated',
            name: colorize(event[:request][:index], :bold),
            type: event[:request][:type],
            runtime: formatted_runtime(event[:runtime])
        else
          print_message '[%<runtime>s] Index %<name>s successfuly updated mapping',
            name: colorize(event[:request][:index], :bold),
            runtime: formatted_runtime(event[:runtime])
        end
      end

      def elasticsearch_update_settings(event)
        print_message '[%<runtime>s] Index %<name>s successfuly updated settings',
          name: colorize(event[:request][:index], :bold),
          runtime: formatted_runtime(event[:runtime])
      end

      def elasticsearch_update_aliases(event)
        actions = event[:request][:body][:actions]
        removed = actions.select { |a| a.key?(:remove) }
        added = actions.select { |a| a.key?(:add) }
        print_message '[%<runtime>s] Successfuly updated aliases:',
          runtime: formatted_runtime(event[:runtime])

        removed.each do |action|
          print_message '%<padding>s-> Index %<name>s removed from alias %<alias>s',
            name: colorize(action[:remove][:index], :bold),
            alias: colorize(action[:remove][:alias], :bold),
            padding: runtime_padding(event[:runtime])
        end
        added.each do |action|
          print_message '%<padding>s-> Index %<name>s added to alias %<alias>s',
            name: colorize(action[:add][:index], :bold),
            alias: colorize(action[:add][:alias], :bold),
            padding: runtime_padding(event[:runtime])
        end
      end

      def elasticsearch_bulk(event)
        print_message('[%<runtime>s] Bulk index %<name>s%<type>s%<wait_interval>s: ',
          runtime: formatted_runtime(event[:runtime]),
          name: colorize(event[:request][:index], :bold),
          type: (event[:request][:type] ? " for type #{colorize(event[:request][:type], :bold)}" : ''),
          wait_interval: (event[:wait_interval].nonzero? ? " (wait interval #{event[:wait_interval]}s)" : ''),
          newline: false,)
        stats = event[:request][:body_stats].select { |_, v| v.nonzero? }.map do |type, count|
          "#{colorize(type, :bold)}: #{count} docs"
        end
        print_message(stats.join(', ') + '.')
      end
    end
  end
end
