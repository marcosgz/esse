# frozen_string_literal: true

RSpec.shared_context 'with geos index definition' do
  let(:states_batches) do
    [
      [
        OpenStruct.new(id: 1, uuid: '11-11', name: 'Il'),
        OpenStruct.new(id: 2, uuid: '22-22', name: 'Md')
      ],

      [
        OpenStruct.new(id: 3, uuid: '33-33', name: 'Ny')
      ]
    ]
  end

  let(:counties_batches) do
    [
      [
        OpenStruct.new(id: 999, uuid: '99-99', name: 'Cook County', state: 'il'),
        OpenStruct.new(id: 888, uuid: '88-88', name: 'Baltimore County', state: 'md')
      ],

      [
        OpenStruct.new(id: 777, uuid: '77-77', name: 'Bronx County', state: 'ny')
      ]
    ]
  end

  let(:total_counties) { counties_batches.flatten.size }
  let(:total_states) { states_batches.flatten.size }
  let(:total_geos) { total_counties + total_states }

  let(:geo_document) do
    Class.new(Esse::Document) do
      def id
        object.id
      end

      def source
        {
          pk: object.id,
          name: object.name,
        }
      end
    end
  end

  let(:state_document) do
    geo_document
  end

  let(:county_document) do
    geo_document
  end

  before do
    # closure for the stub_index block
    dataset = {
      state: states_batches,
      county: counties_batches
    }
    documents = {
      state: state_document,
      county: county_document
    }
    stub_index(:geos) do
      repository :state do
        collection do |**context, &block|
          dataset.fetch(:state).each do |batch|
            states = context[:conditions] ? batch.select(&context[:conditions]) : batch
            block.call(states, **context) unless states.empty?
          end
        end
        document documents.fetch(:state)
      end
      repository :county do
        collection do |**context, &block|
          dataset.fetch(:county).each do |batch|
            counties = context[:conditions] ? batch.select(&context[:conditions]) : batch
            block.call(counties, **context) unless counties.empty?
          end
        end
        document documents.fetch(:county)
        lazy_document_attribute :country do |docs|
          docs.map { |doc| [doc, 'US'] }.to_h
        end
        lazy_document_attribute :cities do |docs|
          docs.map { |doc| [doc, []] }.to_h
        end
      end
    end
  end
end
