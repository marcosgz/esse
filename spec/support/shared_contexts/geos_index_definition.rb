# frozen_string_literal: true

require 'support/serializers'

RSpec.shared_context 'geos index definition' do
  before do
    stub_index(:geos) do
      define_type :state do
        mappings('name' => { 'type' => 'string' }, 'pk' => { 'type' => 'long'})
        collection do |**context, &block|
          [
            [
              OpenStruct.new(id: 1, uuid: '11-11', name: 'Il'),
              OpenStruct.new(id: 2, uuid: '22-22', name: 'Md')
            ],
            [
              OpenStruct.new(id: 3, uuid: '33-33', name: 'Ny')
            ]
          ].each do |batch|
            states = context[:conditions] ? batch.select(&context[:conditions]) : batch
            block.call(states, **context) unless states.empty?
          end
        end
        serializer DummyGeosSerializer
      end
      define_type :county do
        mappings('name' => { 'type' => 'string' }, 'pk' => { 'type' => 'long'})
        collection do |**context, &block|
          [
            [
              OpenStruct.new(id: 999, uuid: '99-99', name: 'Cook County', state: 'il'),
              OpenStruct.new(id: 888, uuid: '88-88', name: 'Baltimore County', state: 'md')
            ],
            [
              OpenStruct.new(id: 777, uuid: '77-77', name: 'Bronx County', state: 'ny')
            ]
          ].each do |batch|
            counties = context[:conditions] ? batch.select(&context[:conditions]) : batch
            block.call(counties, **context) unless counties.empty?
          end
        end
        serializer DummyGeosSerializer
      end
    end
  end
end
