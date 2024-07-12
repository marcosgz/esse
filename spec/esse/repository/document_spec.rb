# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe Esse::Repository do
  describe '.serialize' do
    context 'without a document definition' do
      before { stub_index(:dummies) { repository(:dummy) } }

      specify do
        expect {
          DummiesIndex::Dummy.serialize(double)
        }.to raise_error(
          NotImplementedError,
          'there is no "dummy" document defined for the "DummiesIndex" index',
        )
      end
    end

    context 'with a document definition' do
      let(:dummy) { double(id: 1) }
      let(:optionals) { { name: 'dummy' } }

      before do
        stub_index(:dummies) do
          repository(:dummy) do
            document do |entry, **context|
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

            document do |entry|
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

            document do |entry, **context|
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

      it 'yields serialized objects with document scope' do
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

    context 'with lazy_load_attributes' do
      include_context 'with stories index definition'

      it 'yields serialized objects with lazy attributes when passing lazy_attributes: true' do
        expected_data = []
        expect {
          StoriesIndex::Story.each_serialized_batch(lazy_attributes: true) do |batch|
            expected_data.push(*batch)
          end
        }.not_to raise_error
        expect(expected_data.select { |doc| doc.to_h.key?(:tags) && doc.to_h.key?(:tags_count) }).not_to be_empty
      end

      it 'yields serialized objects without lazy attributes when passing lazy_attributes: false' do
        expected_data = []
        expect {
          StoriesIndex::Story.each_serialized_batch(lazy_attributes: false) do |batch|
            expected_data.push(*batch)
          end
        }.not_to raise_error
        expect(expected_data.select { |doc| doc.to_h.key?(:tags) || doc.to_h.key?(:tags_count) }).to be_empty
      end

      it 'yields serialized objects with lazy attributes when passing specific attributes' do
        expected_data = []
        expect {
          StoriesIndex::Story.each_serialized_batch(lazy_attributes: %i[tags]) do |batch|
            expected_data.push(*batch)
          end
        }.not_to raise_error
        expect(expected_data.select { |doc| doc.to_h.key?(:tags) && !doc.to_h.key?(:tags_count) }).not_to be_empty
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

            document do |entry|
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

            document do |entry, **context|
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

  describe '.document' do
    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          repository :foo do
            document do
            end
          end
        end
      }.not_to raise_error
      expect(klass.repo(:foo).instance_variable_get(:@document_proc)).to be_a_kind_of(Proc)
    end

    specify do
      expect {
        Class.new(Esse::Index) do
          repository :foo do
            document
          end
        end
      }.to raise_error(ArgumentError, "nil is not a valid document. The document should inherit from Esse::Document or respond to `to_h'")
    end

    specify do
      expect {
        Class.new(Esse::Index) do
          repository :foo do
            document :invalid
          end
        end
      }.to raise_error(ArgumentError, ":invalid is not a valid document. The document should inherit from Esse::Document or respond to `to_h'")
    end

    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          repository :foo do
            document(Class.new {
              def as_json
              end
            })
          end
        end
      }.not_to raise_error
      expect(klass.repo(:foo).instance_variable_get(:@document_proc)).to be_a_kind_of(Proc)
    end

    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          repository :foo do
            document(Class.new {
              def to_h
              end
            })
          end
        end
      }.not_to raise_error
      expect(klass.repo(:foo).instance_variable_get(:@document_proc)).to be_a_kind_of(Proc)
    end

    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::Index) do
          repository :foo do
            document(Class.new {
              def call
              end
            })
          end
        end
      }.not_to raise_error
      expect(klass.repo(:foo).instance_variable_get(:@document_proc)).to be_a_kind_of(Proc)
    end
  end

  describe '.coerce_to_document' do
    before { stub_index(:states) { repository(:state) } }

    specify do
      expect {
        StatesIndex::State.send(:coerce_to_document, :invalid)
      }.to raise_error(ArgumentError, ':invalid is not a valid document. The document should be a hash or an instance of Esse::Document')
    end

    specify do
      expect {
        StatesIndex::State.send(:coerce_to_document, OpenStruct.new)
      }.to raise_error(ArgumentError, '#<OpenStruct> is not a valid document. The document should be a hash or an instance of Esse::Document')
    end

    specify do
      expected_object = nil
      expect {
        expected_object = StatesIndex::State.send(:coerce_to_document, Esse::Document.new(nil))
      }.not_to raise_error
      expect(expected_object).to be_a(Esse::Document)
    end

    specify do
      expected_object = nil
      expect {
        expected_object = StatesIndex::State.send(:coerce_to_document, {id: 1})
      }.not_to raise_error
      expect(expected_object).to be_a(Esse::Document)
    end

    specify do
      expected_object = nil
      expect {
        expected_object = StatesIndex::State.send(:coerce_to_document, nil)
      }.not_to raise_error
      expect(expected_object).to be_a(Esse::NullDocument)
    end

    specify do
      expected_object = nil
      expect {
        expected_object = StatesIndex::State.send(:coerce_to_document, false)
      }.not_to raise_error
      expect(expected_object).to be_a(Esse::NullDocument)
    end
  end

  describe '.lazy_document_attributes' do
    let(:repo) do
      Class.new(Esse::Repository) do
      end
    end

    it 'returns a empty hash' do
      expect(repo.lazy_document_attributes).to eq({})
    end

    it 'is a frozen hash' do
      expect(repo.lazy_document_attributes).to be_frozen
    end
  end

  describe '.lazy_document_attribute?' do
    let(:repo) do
      Class.new(Esse::Repository) do
      end
    end

    it 'returns false' do
      expect(repo.send(:lazy_document_attribute?, :foo)).to eq(false)
    end

    context 'with a lazy attribute' do
      let(:repo) do
        Class.new(Esse::Repository) do
          lazy_document_attribute(:foo) { 'bar' }
        end
      end

      it 'returns attribute as it is defined' do
        expect(repo.send(:lazy_document_attribute?, :foo)).to eq(true)
        expect(repo.send(:lazy_document_attribute?, 'foo')).to eq(false)
        expect(repo.send(:lazy_document_attribute?, :bar)).to eq(false)
      end
    end
  end

  describe '.lazy_document_attribute' do
    context 'without a block and class' do
      let(:repo) do
        Class.new(Esse::Repository)
      end

      it 'raises an error' do
        expect {
          repo.lazy_document_attribute(:foo)
        }.to raise_error(ArgumentError, 'A block or a class that responds to `call` is required to define a lazy document attribute')
        expect(repo.lazy_document_attributes).to be_empty
      end
    end

    context 'with a block' do
      let(:repo) do
        Class.new(Esse::Repository) do
          lazy_document_attribute(:foo) { 'bar' }
        end
      end

      it 'defines a lazy attribute' do
        expect(repo.lazy_document_attributes[:foo]).to match_array([
          be < Esse::DocumentLazyAttribute,
          {},
        ])
        expect(repo.send(:lazy_document_attribute?, :foo)).to eq(true)
      end
    end

    context 'with a class that does not respond to `call`' do
      let(:repo) do
        Class.new(Esse::Repository) do
          lazy_document_attribute(:foo, Object)
        end
      end

      it 'raises an error' do
        expect {
          repo.lazy_document_attributes
        }.to raise_error(ArgumentError, 'Object is not a valid lazy document attribute. Class should inherit from Esse::DocumentLazyAttribute or respond to `call`')
      end
    end

    context 'with a class that responds to `call`' do
      let(:repo) do
        Class.new(Esse::Repository) do
          lazy_document_attribute(:foo, TheFooParser)
        end
      end

      before do
        klass = Class.new { def call; end }
        Object.const_set(:TheFooParser, klass)
      end

      after do
        Object.send(:remove_const, :TheFooParser)
      end

      it 'defines a lazy attribute' do
        expect(repo.lazy_document_attributes[:foo]).to match_array([
          TheFooParser,
          {},
        ])
        expect(repo.send(:lazy_document_attribute?, :foo)).to eq(true)
        expect(repo.lazy_document_attributes).to be_frozen
      end
    end

    context 'with a class that inherits from Esse::DocumentLazyAttribute' do
      let(:repo) do
        Class.new(Esse::Repository) do
          lazy_document_attribute(:foo, Class.new(Esse::DocumentLazyAttribute))
        end
      end

      it 'defines a lazy attribute' do
        expect(repo.lazy_document_attributes[:foo]).to match_array([
          be < Esse::DocumentLazyAttribute,
          {},
        ])
        expect(repo.send(:lazy_document_attribute?, :foo)).to eq(true)
        expect(repo.lazy_document_attributes).to be_frozen
      end
    end

    context 'when passing extra options' do
      let(:repo) do
        Class.new(Esse::Repository) do
          lazy_document_attribute(:foo, Class.new(Esse::DocumentLazyAttribute), bar: 'baz')
        end
      end

      it 'defines a lazy attribute' do
        expect(repo.lazy_document_attributes[:foo]).to match_array([
          be < Esse::DocumentLazyAttribute,
          { bar: 'baz' },
        ])
        expect(repo.send(:lazy_document_attribute?, :foo)).to eq(true)
        expect(repo.lazy_document_attributes).to be_frozen
      end
    end
  end

  describe '.fetch_lazy_document_attribute' do
    let(:repo) do
      Class.new(Esse::Repository) do
        lazy_document_attribute(:foo) { 'bar' }
      end
    end

    it 'returns a lazy attribute' do
      expect(repo.fetch_lazy_document_attribute(:foo)).to be_a_kind_of(Esse::DocumentLazyAttribute)
    end

    it 'raises an error when the attribute is not defined' do
      expect {
        repo.fetch_lazy_document_attribute(:bar)
      }.to raise_error(ArgumentError, 'Attribute :bar is not defined as a lazy document attribute')
    end
  end
end
