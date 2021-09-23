module Hooks
  # Allows to set the Elasticsearch version to be used in the tests using real
  module PubSub
    def self.included(base)
      base.include InstanceMethods
      base.before(:example) do |example|
        if example.metadata[:events]
          Store.clear
        end
        Array(example.metadata[:events]).each do |event_name|
          Esse::Events.subscribe(event_name) do |event|
            Store.push_event(event_name, event)
          end
        end
      end
      base.after(:example) do |example|
        if example.metadata[:events]
          Esse::Events.__bus__.listeners.clear
        end
      end
    end

    module InstanceMethods
      def assert_event(event_name, expected_data = nil)
        msg = "Expected event #{event_name.inspect} to be published"
        msg += " with data #{expected_data.inspect}." if expected_data
        if (values = Store.values_for(event_name)).any?
          msg += "\nActual data:"
          values.each do |value|
            msg += "\n  #{value.inspect}"
          end
        end
        expect(Store.include?(event_name, expected_data)).to be_truthy, msg
      end

      def refute_event(event_name, expected_data = nil)
        msg = "Expected event #{event_name.inspect} to not be published"
        msg += " with data #{expected_data.inspect}." if expected_data
        expect(Store.include?(event_name, expected_data)).to be_falsey, msg
      end
    end

    class Store
      class << self
        extend Forwardable
        def_delegators :data, :clear, :size

        def push_event(event_name, event)
          data << [event_name, event.payload]
        end

        def include?(event_name, *payloads)
          data.any? do |name, payload|
            name == event_name && (payloads.none? || payloads.all? { |to_match| payload?(payload, to_match) })
          end
        end

        def values_for(event_name)
          data.select { |name, _| name == event_name }.map(&:last).flatten
        end

        protected

        def payload?(original, expected)
          case expected
          when Array
            expected.all? { |key| original.key?(key) }
          when Hash
            return false unless expected.is_a?(Hash)

            original.slice(*expected.keys).all? do |key, value|
              payload?(value, expected[key])
            end
          else
            original == expected
          end
        end

        def data
          @data ||= []
        end
      end
    end
  end
end
