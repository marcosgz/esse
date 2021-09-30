# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Events::Publisher do
  subject(:publisher) do
    Class.new {
      include Esse::Events::Publisher

      register_event :test_event
    }
  end

  # describe '.[]' do
  #   it 'creates a publisher extension with provided id' do
  #     publisher = Class.new do
  #       include Esse::Events::Publisher[:my_publisher]
  #     end

  #     expect(Esse::Events::Publisher.registry[:my_publisher]).to be(publisher)
  #   end

  #   it 'does not allow same id to be used for than once' do
  #     create_publisher = -> do
  #       Class.new do
  #         include Esse::Events::Publisher[:my_publisher]
  #       end
  #     end

  #     create_publisher.()

  #     expect { create_publisher.() }.to raise_error(Esse::Events::PublisherAlreadyRegisteredError, /my_publisher/)
  #   end
  # end

  describe '.subscribe' do
    it 'subscribes a listener' do
      listener = ->(*) {}

      publisher.subscribe(:test_event, &listener)

      expect(publisher.subscribed?(listener)).to be(true)
    end

    it 'raises an exception when subscribing to an unregister event' do
      listener = ->(*) {}

      expect {
        publisher.subscribe(:not_register, &listener)
      }.to raise_error(Esse::Events::InvalidSubscriberError, /not_register/)
    end
  end

  describe '.register_event' do
    it 'registers a new event' do
      listener = ->(*) {}

      publisher.register_event(:test_another_event).subscribe(:test_another_event, &listener)

      expect(publisher.subscribed?(listener)).to be(true)
    end
  end

  describe '.subscribe' do
    it 'subscribes a listener function' do
      listener = ->(*) {}

      publisher.subscribe(:test_event, &listener)

      expect(publisher.subscribed?(listener)).to be(true)
    end

    it 'subscribes and unsubscribe a listener object' do
      listener = Class.new do
        attr_reader :captured

        def initialize
          @captured = []
        end

        def on_test_event(event)
          captured << event[:message]
        end
      end.new

      publisher.subscribe(listener).publish(:test_event, message: 'it works')
      expect(publisher.subscribed?(listener)).to be(true)
      expect(listener.captured).to eql(['it works'])

      publisher.unsubscribe(listener)

      expect(publisher.subscribed?(listener)).to be(false)
      publisher.publish(:test_event, message: 'it works')

      expect(listener.captured).to eql(['it works'])
    end

    it 'raises an exception when subscribing with no methods to execute' do
      listener = Object.new

      expect {
        publisher.subscribe(listener)
      }.to raise_error(Esse::Events::InvalidSubscriberError, /never be executed/)
    end

    it 'does not raise an exception when subscriber has methods for notification' do
      listener = Object.new
      def listener.on_test_event
        nil
      end
      expect { publisher.subscribe(listener) }.not_to raise_error
    end
  end

  describe '.publish' do
    it 'publishes an event' do
      result = []
      listener = ->(event) { result << event[:message] }

      publisher.subscribe(:test_event, &listener).publish(:test_event, message: 'it works')

      expect(result).to eql(['it works'])
    end

    it 'raises an exception when publishing an unregistered event' do
      expect {
        publisher.publish(:unregistered_event, {})
      }.to raise_error(Esse::Events::UnregisteredEventError, /unregistered_event/)
    end
  end

  describe '.instrument' do
    it 'publishes an event' do
      result = []
      listener = ->(event) { result << event.payload.slice(:external_msg, :internal_msg, :runtime, :__started_at__) }

      publisher.subscribe(:test_event, &listener).instrument(:test_event, external_msg: 'e') do |payload|
        payload[:internal_msg] = 'i'
        sleep 0.1
      end

      expect(result.size).to eq(1)
      expect(result.dig(0, :external_msg)).to eq('e')
      expect(result.dig(0, :internal_msg)).to eq('i')
      expect(result.dig(0, :runtime)).to be_within(0.1).of(0.1)
      expect(result.dig(0, :__started_at__)).to eq(nil)
    end

    it 'does not publishes an event if block throws an exception' do
      result = []
      listener = ->(event) { result << event }

      expect {
        publisher.subscribe(:test_event, &listener).instrument(:test_event) do |payload|
          payload[:msg] = 'ignore'
          raise RuntimeError
        end
      }.to raise_error(RuntimeError)

      expect(result.size).to eq(0)
    end

    it 'raises an exception when publishing an unregistered event' do
      expect {
        publisher.instrument(:unregistered_event, {}) { |*| }
      }.to raise_error(Esse::Events::UnregisteredEventError, /unregistered_event/)
    end
  end
end
