# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe Esse::Repository do
  describe '.serialize' do
    context 'without a serializer definition' do
      before { stub_index(:dummies) { repository(:dummy) } }

      specify do
        expect {
          DummiesIndex::Dummy.serialize(double)
        }.to raise_error(
          NotImplementedError,
          'there is no "dummy" serializer defined for the "DummiesIndex" index',
        )
      end
    end

    context 'with a serializer definition' do
      let(:dummy) { double(id: 1) }
      let(:optionals) { { name: 'dummy' } }

      before do
        stub_index(:dummies) do
          repository(:dummy) do
            serializer do |entry, **context|
              {
                _id: entry.id,
              }.merge(context)
            end
          end
        end
      end

      specify do
        expect(DummiesIndex::Dummy.serialize(dummy, **optionals)).to eq(
          Esse::HashDocument.new(
            _id: 1,
            name: 'dummy',
          )
        )
      end
    end
  end

  describe '.each_serialized_batch' do
    context 'without collection arguments' do
      before do
        stub_index(:states) do
          repository(:state) do
            collection do |&block|
              data = [
                OpenStruct.new(id: 1, name: 'Il'),
                OpenStruct.new(id: 2, name: 'Md'),
                OpenStruct.new(id: 3, name: 'Ny')
              ]
              data.each do |datum|
                block.call([datum])
              end
            end

            serializer do |entry|
              {
                _id: entry.id,
                name: entry.name,
              }
            end
          end
        end
      end

      it 'yields serialized objects without arguments' do
        expected_data = []
        expect {
          StatesIndex::State.each_serialized_batch { |hash| expected_data << hash }
        }.not_to raise_error
        expect(expected_data).to match_array(
          [
            [Esse::HashDocument.new(_id: 1, name: 'Il')],
            [Esse::HashDocument.new(_id: 2, name: 'Md')],
            [Esse::HashDocument.new(_id: 3, name: 'Ny')],
          ],
        )
      end
    end

    context 'with extra collection arguments' do
      before do
        stub_index(:states) do
          repository(:state) do
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
      end

      it 'yields serialized objects without arguments' do
        expected_data = []
        expect {
          StatesIndex::State.each_serialized_batch { |hash| expected_data << hash }
        }.not_to raise_error
        expect(expected_data).to match_array(
          [
            [Esse::HashDocument.new(_id: 1, name: 'Il')],
            [Esse::HashDocument.new(_id: 2, name: 'Md')],
            [Esse::HashDocument.new(_id: 3, name: 'Ny')],
          ],
        )
      end

      it 'yields serialized objects with a collection filter' do
        expected_data = []
        expect {
          StatesIndex::State.each_serialized_batch(filter: ->(state) { state.id > 2 }) { |hash| expected_data << hash }
        }.not_to raise_error
        expect(expected_data).to match_array(
          [
            [Esse::HashDocument.new(_id: 1, name: 'Il')],
            [Esse::HashDocument.new(_id: 2, name: 'Md')],
          ],
        )
      end

      it 'yields serialized objects with serializer scope' do
        expected_data = []
        expect {
          StatesIndex::State.each_serialized_batch(uppercase: true) { |hash| expected_data << hash }
        }.not_to raise_error
        expect(expected_data).to match_array(
          [
            [Esse::HashDocument.new(_id: 1, name: 'IL')],
            [Esse::HashDocument.new(_id: 2, name: 'MD')],
            [Esse::HashDocument.new(_id: 3, name: 'NY')],
          ],
        )
      end
    end
  end

  describe '.documents' do
    context 'without collection arguments' do
      before do
        stub_index(:states) do
          repository(:state) do
            collection do |&block|
              data = [
                OpenStruct.new(id: 1, name: 'Il'),
                OpenStruct.new(id: 2, name: 'Md'),
                OpenStruct.new(id: 3, name: 'Ny')
              ]
              data.each do |datum|
                block.call([datum])
              end
            end

            serializer do |entry|
              {
                _id: entry.id,
                name: entry.name,
              }
            end
          end
        end
      end

      it 'returns Enumerator with serialized objects without arguments' do
        expect(StatesIndex::State.documents).to be_a(Enumerator)
        expect(StatesIndex::State.documents.to_a).to match_array(
          [
            Esse::HashDocument.new(_id: 1, name: 'Il'),
            Esse::HashDocument.new(_id: 2, name: 'Md'),
            Esse::HashDocument.new(_id: 3, name: 'Ny'),
          ]
        )
      end
    end

    context 'with extra collection arguments' do
      before do
        stub_index(:states) do
          repository(:state) do
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
      end

      it 'returns Enumerator with serialized objects without arguments' do
        expect(StatesIndex::State.documents).to be_a(Enumerator)
        expect(StatesIndex::State.documents.to_a).to match_array(
          [
            Esse::HashDocument.new(_id: 1, name: 'Il'),
            Esse::HashDocument.new(_id: 2, name: 'Md'),
            Esse::HashDocument.new(_id: 3, name: 'Ny'),
          ]
        )
      end

      it 'returns enumerator with all serialized objects with a collection filter' do
        expect(StatesIndex::State.documents(filter: ->(state) { state.id > 2 }).take(3)).to match_array(
          [
            Esse::HashDocument.new(_id: 1, name: 'Il'),
            Esse::HashDocument.new(_id: 2, name: 'Md'),
          ],
        )
      end
    end
  end

  describe '.serializer' do
    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          repository :foo do
            serializer do
            end
          end
        end
      }.not_to raise_error
      expect(klass.repo(:foo).instance_variable_get(:@serializer_proc)).to be_a_kind_of(Proc)
    end

    specify do
      expect {
        Class.new(Esse::Index) do
          repository :foo do
            serializer
          end
        end
      }.to raise_error(ArgumentError, "nil is not a valid serializer. The serializer should inherit from Esse::Serializer or respond to `to_h'")
    end

    specify do
      expect {
        Class.new(Esse::Index) do
          repository :foo do
            serializer :invalid
          end
        end
      }.to raise_error(ArgumentError, ":invalid is not a valid serializer. The serializer should inherit from Esse::Serializer or respond to `to_h'")
    end

    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          repository :foo do
            serializer(Class.new {
              def as_json
              end
            })
          end
        end
      }.not_to raise_error
      expect(klass.repo(:foo).instance_variable_get(:@serializer_proc)).to be_a_kind_of(Proc)
    end

    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          repository :foo do
            serializer(Class.new {
              def to_h
              end
            })
          end
        end
      }.not_to raise_error
      expect(klass.repo(:foo).instance_variable_get(:@serializer_proc)).to be_a_kind_of(Proc)
    end

    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          repository :foo do
            serializer(Class.new {
              def call
              end
            })
          end
        end
      }.not_to raise_error
      expect(klass.repo(:foo).instance_variable_get(:@serializer_proc)).to be_a_kind_of(Proc)
    end
  end

  describe '.coerce_to_document' do
    before { stub_index(:states) { repository(:state) } }

    specify do
      expect {
        StatesIndex::State.coerce_to_document(:invalid)
      }.to raise_error(ArgumentError, ':invalid is not a valid document. The document should be a hash or an instance of Esse::Serializer')
    end

    specify do
      expect {
        StatesIndex::State.coerce_to_document(OpenStruct.new)
      }.to raise_error(ArgumentError, '#<OpenStruct> is not a valid document. The document should be a hash or an instance of Esse::Serializer')
    end

    specify do
      expected_object = nil
      expect {
        expected_object = StatesIndex::State.coerce_to_document(Esse::Serializer.new(nil))
      }.not_to raise_error
      expect(expected_object).to be_a(Esse::Serializer)
    end

    specify do
      expected_object = nil
      expect {
        expected_object = StatesIndex::State.coerce_to_document({id: 1})
      }.not_to raise_error
      expect(expected_object).to be_a(Esse::HashDocument)
    end

    specify do
      expected_object = nil
      expect {
        expected_object = StatesIndex::State.coerce_to_document(nil)
      }.not_to raise_error
      expect(expected_object).to be_a(Esse::NullDocument)
    end

    specify do
      expected_object = nil
      expect {
        expected_object = StatesIndex::State.coerce_to_document(false)
      }.not_to raise_error
      expect(expected_object).to be_a(Esse::NullDocument)
    end
  end
end
