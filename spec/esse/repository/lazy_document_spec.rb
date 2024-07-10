# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Repository do
  describe '.documents_for_lazy_attribute' do
    context 'when the attribute is not defined' do
      let(:repo) { Class.new(Esse::Repository) }

      it 'raises an error' do
        expect { repo.documents_for_lazy_attribute(:foo) }.to raise_error(ArgumentError)
      end
    end

    context 'when the attribute is defined and its result is not a hash' do
      let(:repo) do
        Class.new(Esse::Repository) do
          lazy_document_attribute :city_names do |_|
            Object.new
          end
        end
      end

      it 'returns an empty array when no ids are provided' do
        expect(repo.documents_for_lazy_attribute(:city_names)).to eq([])
      end

      it 'returns an empty array when no ids are found' do
        expect(repo.documents_for_lazy_attribute(:city_names, '3')).to eq([])
      end
    end

    context 'when the attribute is defined and its result is hash with id as key' do
      let(:repo) do
        Class.new(Esse::Repository) do
          lazy_document_attribute :city_names do |docs|
            {
              '1' => 'Moscow',
              '2' => 'London',
            }
          end
        end
      end

      it 'returns an empty array when no ids are provided' do
        expect(repo.documents_for_lazy_attribute(:city_names)).to eq([])
      end

      it 'returns an empty array when no ids are found' do
        expect(repo.documents_for_lazy_attribute(:city_names, '3')).to eq([])
      end

      it 'returns an array of documents that match with the provided ids' do
        docs = repo.documents_for_lazy_attribute(:city_names, '2')
        expect(docs).to eq([
          Esse::HashDocument.new(_id: '2', city_names: 'London')
        ])
      end

      it 'returns an array of documents that match with the provided LazyDocumentHeader' do
        docs = repo.documents_for_lazy_attribute(:city_names, Esse::LazyDocumentHeader.coerce(id: '2'))
        expect(docs).to eq([
          Esse::HashDocument.new(_id: '2', city_names: 'London')
        ])
      end
    end

    context 'when the attribute is defined and its result is hash with LazyDocumentHeader as key' do
      let(:repo) do
        Class.new(Esse::Repository) do
          lazy_document_attribute :city_names do |docs|
            {
              Esse::LazyDocumentHeader.coerce(id: '1') => 'Moscow',
              Esse::LazyDocumentHeader.coerce(id: '2') => 'London',
            }
          end
        end
      end

      it 'returns an empty array when no ids are provided' do
        expect(repo.documents_for_lazy_attribute(:city_names)).to eq([])
      end

      it 'returns an empty array when no ids are found' do
        expect(repo.documents_for_lazy_attribute(:city_names, '3')).to eq([])
      end

      it 'returns an array of documents that match with the provided ids' do
        docs = repo.documents_for_lazy_attribute(:city_names, '2')
        expect(docs).to eq([
          Esse::HashDocument.new(_id: '2', city_names: 'London')
        ])
      end

      it 'returns an array of documents that match with the provided LazyDocumentHeader' do
        docs = repo.documents_for_lazy_attribute(:city_names, Esse::LazyDocumentHeader.coerce(id: '2'))
        expect(docs).to eq([
          Esse::HashDocument.new(_id: '2', city_names: 'London')
        ])
      end

      it 'do not include duplicate documents' do
        docs = repo.documents_for_lazy_attribute(:city_names, '2', '2', Esse::LazyDocumentHeader.coerce(id: '2'))
        expect(docs).to eq([
          Esse::HashDocument.new(_id: '2', city_names: 'London')
        ])
      end
    end

    context 'when the result is a hash includes blank values' do
      let(:repo) do
        Class.new(Esse::Repository) do
          lazy_document_attribute :city_names do |docs|
            {
              '1' => 'Moscow',
              '2' => 'London',
              '3' => nil,
              '4' => '',
            }
          end
        end
      end

      it 'returns an array of documents that match with the provided ids' do
        docs = repo.documents_for_lazy_attribute(:city_names, '2', '3', '4')
        expect(docs).to eq([
          Esse::HashDocument.new(_id: '2', city_names: 'London'),
          Esse::HashDocument.new(_id: '3', city_names: nil),
          Esse::HashDocument.new(_id: '4', city_names: ''),
        ])
      end
    end
  end

  describe '.update_documents_attribute' do
    let(:repo) do
      Class.new(Esse::Repository) do
        lazy_document_attribute :city_names do |docs|
          {
            '1' => 'Moscow',
            '2' => 'London',
          }
        end
      end
    end

    it 'does nothing when no ids are provided' do
      expect(repo.index).not_to receive(:bulk)
      repo.update_documents_attribute(:city_names)
    end

    it 'does nothing when no ids are found' do
      expect(repo.index).not_to receive(:bulk)
      repo.update_documents_attribute(:city_names, '3')
    end

    it 'updates the documents' do
      expect(repo.index).to receive(:bulk).with(
        update: [
          Esse::HashDocument.new(_id: '2', city_names: 'London')
        ]
      )
      repo.update_documents_attribute(:city_names, '2')
    end
  end
end
