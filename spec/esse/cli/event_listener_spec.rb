# frozen_string_literal: true

require 'spec_helper'
require 'esse/primitives/output'
require 'esse/events/event'
require 'esse/cli/event_listener'

RSpec.describe Esse::CLI::EventListener do
  describe '.[]' do
    it 'returns event method' do
      expect(described_class['elasticsearch.create_index']).to eq(described_class.method(:elasticsearch_create_index))
    end

    it 'returns nil when listener does not implement the event method' do
      expect(described_class['elasticsearch.missing_event_name']).to eq(nil)
    end
  end

  describe '.elasticsearch_update_aliases' do
    subject do
      described_class['elasticsearch.update_aliases'].call(event)
    end

    let(:event_id) { 'elasticsearch.update_aliases' }
    let(:event) do
      Esse::Events::Event.new(event_id, payload)
    end

    let(:payload) do
      {
        runtime: 1.32,
        request: {
          body: {
            actions: [
              *remove_actions,
              *add_actions,
            ]
          }
        }
      }
    end
    let(:remove_actions) { [] }
    let(:add_actions) { [] }

    context 'without actions' do
      it 'prints message' do
        expect { subject }.to output(/Successfuly updated aliases/).to_stdout
      end
    end

    context 'with remove and add action' do
      let(:remove_actions) do
        [
          { remove: { index: 'index_name_123', alias: 'index_name' } }
        ]
      end

      let(:add_actions) do
        [
          { add: { index: 'index_name_456', alias: 'index_name' } }
        ]
      end

      it 'prints message' do
        expect { subject }.to output(<<~MSG).to_stdout
          [#{formatted_runtime(1.32)}] Successfuly updated aliases:
                    -> Index #{colorize("index_name_123", :bold)} removed from alias #{colorize("index_name", :bold)}
                    -> Index #{colorize("index_name_456", :bold)} added to alias #{colorize("index_name", :bold)}
        MSG
      end
    end

    context 'with multiple remove and add action' do
      let(:remove_actions) do
        [
          { remove: { index: 'index_name_123', alias: 'index_name' } },
          { remove: { index: 'index_name_456', alias: 'index_name' } },
        ]
      end

      let(:add_actions) do
        [
          { add: { index: 'index_name_789', alias: 'index_name' } }
        ]
      end

      it 'prints message' do
        expect { subject }.to output(<<~MSG).to_stdout
          [#{formatted_runtime(1.32)}] Successfuly updated aliases:
                    -> Index #{colorize("index_name_123", :bold)} removed from alias #{colorize("index_name", :bold)}
                    -> Index #{colorize("index_name_456", :bold)} removed from alias #{colorize("index_name", :bold)}
                    -> Index #{colorize("index_name_789", :bold)} added to alias #{colorize("index_name", :bold)}
        MSG
      end
    end
  end

  def colorize(*args)
    Esse::Output.colorize(*args)
  end

  def formatted_runtime(runtime)
    Esse::Output.formatted_runtime(runtime)
  end
end
