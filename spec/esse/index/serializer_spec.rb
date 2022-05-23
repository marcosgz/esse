# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'
require 'support/collections'

RSpec.describe Esse::Index do
  describe '.serialize' do
    context 'without a serializer definition' do
      before { stub_index(:dummies) {} }

      specify do
        expect {
          DummiesIndex.serialize(double)
        }.to raise_error(
          NotImplementedError,
          'there is no :__default__ serializer defined for the "DummiesIndex" index',
        )
      end
    end

    context 'with a serializer definition' do
      let(:dummy) { double(id: 1) }
      let(:optionals) { { name: 'dummy' } }

      before do
        stub_index(:dummies) do
          serializer do |entry, **context|
            {
              _id: entry.id,
            }.merge(context)
          end
        end
      end

      specify do
        expect(DummiesIndex.serialize(dummy, **optionals)).to eq(
          _id: 1,
          name: 'dummy',
        )
      end
    end
  end

  describe '.each_serialized_batch' do
    before do
      stub_index(:states) do
        collection do |**context, &block|
          data = [
            OpenStruct.new(id: 1, name: 'Il'),
            OpenStruct.new(id: 2, name: 'Md'),
            OpenStruct.new(id: 3, name: 'Ny')
          ]
          data.delete_if(&context[:filter]) if context[:filter]
          data.each do |datum|
            block.call([datum], **context)
          end
        end

        serializer do |entry, **context|
          {
            _id: entry.id,
            name: (context[:uppercase] ? entry.name.upcase : entry.name),
          }
        end
      end
    end

    it 'yields serialized objects without arguments' do
      expected_data = []
      expect {
        StatesIndex.each_serialized_batch { |hash| expected_data << hash }
      }.not_to raise_error
      expect(expected_data).to match_array(
        [
          [{ _id: 1, name: 'Il' }],
          [{ _id: 2, name: 'Md' }],
          [{ _id: 3, name: 'Ny' }]
        ],
      )
    end

    it 'yields serialized objects with a collection filter' do
      expected_data = []
      expect {
        StatesIndex.each_serialized_batch(filter: ->(state) { state.id > 2 }) { |hash| expected_data << hash }
      }.not_to raise_error
      expect(expected_data).to match_array(
        [
          [{ _id: 1, name: 'Il' }],
          [{ _id: 2, name: 'Md' }]
        ],
      )
    end

    it 'yields serialized objects with serializer scope' do
      expected_data = []
      expect {
        StatesIndex.each_serialized_batch(uppercase: true) { |hash| expected_data << hash }
      }.not_to raise_error
      expect(expected_data).to match_array(
        [
          [{ _id: 1, name: 'IL' }],
          [{ _id: 2, name: 'MD' }],
          [{ _id: 3, name: 'NY' }]
        ],
      )
    end

    context "when collection yields data with additional context" do
      before do
        stub_index(:geos) do
          collection do |**_kwargs, &block|
            data = [
              OpenStruct.new(id: 1, name: 'Il'),
              OpenStruct.new(id: 2, name: 'Md'),
              OpenStruct.new(id: 3, name: 'Ny')
            ]
            labels = {
              1 => 'Illinois',
              2 => 'Maryland',
              3 => 'New York',
            }
            block.call(data, labels: labels)
          end

          serializer do |struct, labels:, **_|
            {
              _id: struct.id,
              name: labels[struct.id],
            }
          end
        end
      end

      specify do
        expected_data = []
        expect {
          GeosIndex.each_serialized_batch { |batch| expected_data.push(*batch) }
        }.not_to raise_error
        expect(expected_data).to match_array(
          [
            { _id: 1, name: 'Illinois' },
            { _id: 2, name: 'Maryland' },
            { _id: 3, name: 'New York' }
          ],
        )
      end
    end

    context "when collection yields data with additional context" do
      before do
        stub_index(:geos) do
          collection do |**_kwargs, &block|
            labels = { 1 => 'Illinois', 2 => 'Maryland', 3 => 'New York' }
            block.call([[1, {}], [2, {}]], labels: labels)
          end

          serializer do |datum, labels:, **_|
            id, _ = datum
            { _id: id, name: labels[id] }
          end
        end
      end

      it "does not flatten batch arrays" do
        expected_data = []
        expect {
          GeosIndex.each_serialized_batch { |batch| expected_data.push(*batch) }
        }.not_to raise_error
        expect(expected_data).to match_array(
          [
            { _id: 1, name: 'Illinois' },
            { _id: 2, name: 'Maryland' },
          ],
        )
      end
    end
  end

  describe '.documents' do
    before do
      stub_index(:states) do
        collection do |**context, &block|
          data = [
            OpenStruct.new(id: 1, name: 'Il'),
            OpenStruct.new(id: 2, name: 'Md'),
            OpenStruct.new(id: 3, name: 'Ny')
          ]
          data.delete_if(&context[:filter]) if context[:filter]
          data.each do |datum|
            block.call([datum], **context)
          end
        end

        serializer do |entry, **context|
          {
            _id: entry.id,
            name: (context[:uppercase] ? entry.name.upcase : entry.name),
          }
        end
      end
    end

    it 'returns an Enumerator without arguments' do
      expect(StatesIndex.documents).to be_a_kind_of(Enumerator)
      expect(StatesIndex.documents.count).to eq(3)
    end

    it 'forward filters to the collection' do
      expect(StatesIndex.documents(filter: ->(state) { state.id > 2 }).take(3)).to match_array(
        [
          { _id: 1, name: 'Il' },
          { _id: 2, name: 'Md' },
        ],
      )
    end
  end

  describe '.serializer' do
    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          serializer do
          end
        end
      }.not_to raise_error
      expect(klass.instance_variable_get(:@serializer_proc)[:__default__]).to be_a_kind_of(Proc)
    end

    specify do
      expect {
        Class.new(Esse::Index) do
          serializer
        end
      }.to raise_error(ArgumentError, 'nil is not a valid serializer. The serializer should respond with `to_h` instance method.')
    end

    specify do
      expect {
        Class.new(Esse::Index) do
          serializer :__default__, :invalid
        end
      }.to raise_error(ArgumentError, ':invalid is not a valid serializer. The serializer should respond with `to_h` instance method.')
    end

    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          serializer(Class.new {
                       def as_json
                       end
                     })
        end
      }.not_to raise_error
      expect(klass.instance_variable_get(:@serializer_proc)[:__default__]).to be_a_kind_of(Proc)
    end

    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          serializer(Class.new {
                       def to_h
                       end
                     })
        end
      }.not_to raise_error
      expect(klass.instance_variable_get(:@serializer_proc)[:__default__]).to be_a_kind_of(Proc)
    end

    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          serializer(Class.new {
                       def call
                       end
                     })
        end
      }.not_to raise_error
      expect(klass.instance_variable_get(:@serializer_proc)[:__default__]).to be_a_kind_of(Proc)
    end
  end
end
