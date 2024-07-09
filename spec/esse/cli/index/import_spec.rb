# frozen_string_literal: true

require 'spec_helper'
require 'support/cli_helpers'

RSpec.describe Esse::CLI::Index, type: :cli do
  describe '#import' do
    it 'raises an error if no index name is given' do
      expect {
        cli_exec(%w[index import])
      }.to raise_error(Esse::CLI::InvalidOption, /You must specify at least one index class/)
    end

    it 'raises an error if given argument is not a valid index class' do
      expect {
        cli_exec(%w[index import Esse::Config])
      }.to raise_error(Esse::CLI::InvalidOption, /Esse::Config must be a subclass of Esse::Index/)
    end

    it 'raises an error if given argument is not defined' do
      expect {
        cli_exec(%w[index import NotDefinedIndexName])
      }.to raise_error(Esse::CLI::InvalidOption, /Unrecognized index class: "NotDefinedIndexName"/)
    end

    context 'with a valid index name' do
      before do
        stub_index(:counties)
        stub_index(:cities) do
          repository :city do
          end
        end
      end

      specify do
        expect(CountiesIndex).to receive(:import).and_return(true)
        cli_exec(%w[index import CountiesIndex])
      end

      specify do
        expect(CountiesIndex).to receive(:import).with(suffix: 'foo', context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --suffix=foo])
      end

      specify do
        expect(CitiesIndex).to receive(:import).with('city', suffix: 'foo', context: {}).and_return(true)
        cli_exec(%w[index import CitiesIndex --suffix=foo --repo=city])
      end

      specify do
        expect(CountiesIndex).to receive(:import).with(suffix: 'foo', context: {validate: 'email', file: 'test.csv'}).and_return(true)
        cli_exec(%w[index import CountiesIndex --suffix=foo --context=validate:email file:test.csv])
      end

      it 'allows multiple indices' do
        expect(CountiesIndex).to receive(:import).and_return(true)
        expect(CitiesIndex).to receive(:import).and_return(true)
        cli_exec(%w[index import CountiesIndex CitiesIndex])
      end

      it 'allows --eager-include-document-attributes as a comma separated list' do
        expect(CountiesIndex).to receive(:import).with(eager_include_document_attributes: %w[foo bar], context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --eager-include-document-attributes=foo,bar])
      end

      it 'allows --lazy-update-document-attributes as a single value' do
        expect(CountiesIndex).to receive(:import).with(lazy_update_document_attributes: %w[foo], context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --lazy-update-document-attributes=foo])
      end

      it 'allows --lazy-update-document-attributes as true' do
        expect(CountiesIndex).to receive(:import).with(lazy_update_document_attributes: true, context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --lazy-update-document-attributes=true])
      end

      it 'allows --lazy-update-document-attributes as false' do
        expect(CountiesIndex).to receive(:import).with(context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --lazy-update-document-attributes=false])
      end

      it 'allows --lazy-update-document-attributes as a comma separated list' do
        expect(CountiesIndex).to receive(:import).with(lazy_update_document_attributes: %w[foo bar], context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --lazy-update-document-attributes=foo,bar])
      end

      it 'allows --lazy-update-document-attributes as a single value' do
        expect(CountiesIndex).to receive(:import).with(lazy_update_document_attributes: %w[foo], context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --lazy-update-document-attributes=foo])
      end

      it 'allows --lazy-update-document-attributes as true' do
        expect(CountiesIndex).to receive(:import).with(lazy_update_document_attributes: true, context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --lazy-update-document-attributes=true])
      end

      it 'allows --lazy-update-document-attributes as false' do
        expect(CountiesIndex).to receive(:import).with(context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --lazy-update-document-attributes=false])
      end
    end
  end
end
