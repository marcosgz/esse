# frozen_string_literal: true

require_relative 'events/publisher'

module Esse
  # Extension used for classes that can pub/sub events
  #
  # Examples:
  #
  #   # Publish an event
  #   Esse::Events.publish('elasticsearch.create_index', { definition: {index_name: 'my_index'} })
  #   # Subscribe to an event
  #   Esse::Events.subscribe('elasticsearch.create_index') do |event|
  #     puts event.payload
  #   end
  #
  #   # Publish an event using instrumentation
  #   Esse::Events.instrument('elasticsearch.create_index') do |payload|
  #     payload[:definition] = {index_name: 'my_index'}
  #     # Some slow action
  #   end
  #   Esse::Events.subscribe('elasticsearch.create_index') do |event|
  #     puts event.payload[:runtime] # Extra information about the amount of time the action took
  #   end
  #
  #   # Attach a listener to the event bus
  #   class MyEventListener
  #     def on_elasticsearch_create_index(event)
  #       puts event.payload
  #     end
  #   end
  #   listener = MyEventListener.new
  #   Esse::Events.attach(listener)
  #   # Dettash the listener
  #   Esse::Events.detach(listener)
  #
  #
  module Events
    include Publisher

    register_event 'elasticsearch.close'
    register_event 'elasticsearch.open'
    register_event 'elasticsearch.create_index'
    register_event 'elasticsearch.delete_index'
    register_event 'elasticsearch.update_mapping'
    register_event 'elasticsearch.update_settings'
  end
end
