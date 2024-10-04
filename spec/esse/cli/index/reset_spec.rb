# frozen_string_literal: true

require 'spec_helper'
require 'support/cli_helpers'

RSpec.describe Esse::CLI::Index, type: :cli do
  describe '#reset' do
    it 'raises an error if no index name is given' do
      expect {
        cli_exec(%w[index reset])
      }.to raise_error(Esse::CLI::InvalidOption, /You must specify at least one index class/)
    end

    it 'raises an error if given argument is not a valid index class' do
      expect {
        cli_exec(%w[index reset Esse::Config])
      }.to raise_error(Esse::CLI::InvalidOption, /Esse::Config must be a subclass of Esse::Index/)
    end

    it 'raises an error if given argument is not defined' do
      expect {
        cli_exec(%w[index reset NotDefinedIndexName])
      }.to raise_error(Esse::CLI::InvalidOption, /Unrecognized index class: "NotDefinedIndexName"/)
    end

    context 'with a valid index name' do
      let(:defaults) { { import: true, optimize: true, reindex: false } }

      before do
        stub_index(:counties)
        stub_index(:cities)
      end

      specify do
        expect(CountiesIndex).to receive(:reset_index).and_return(true)
        cli_exec(%w[index reset CountiesIndex])
      end

      specify do
        expect(CountiesIndex).to receive(:reset_index).with(**defaults, suffix: 'foo').and_return(true)
        cli_exec(%w[index reset CountiesIndex --suffix=foo])
      end

      it 'allows multiple indices' do
        expect(CountiesIndex).to receive(:reset_index).and_return(true)
        expect(CitiesIndex).to receive(:reset_index).and_return(true)
        cli_exec(%w[index reset CountiesIndex CitiesIndex])
      end

      it 'allows to reset all indices at once using "all" wildcard' do
        expect(Esse::Index).to receive(:descendants).at_least(1).and_return([CountiesIndex])
        expect(CountiesIndex).to receive(:reset_index).and_return(true)
        cli_exec(%w[index reset all])
      end

      it 'allows to pass --no-optimize' do
        expect(CountiesIndex).to receive(:reset_index).with(**defaults, optimize: false).and_return(true)
        cli_exec(%w[index reset CountiesIndex --no-optimize])
      end

      it 'allows to pass --settings as a hash with imploded values' do
        expect(CountiesIndex).to receive(:reset_index).with(**defaults, settings: { 'index.refresh_interval': '-1' }).and_return(true)
        cli_exec(%w[index reset CountiesIndex --settings=index.refresh_interval:-1])
      end

      it 'raises an error if --import and --reindex are used together' do
        expect {
          cli_exec(%w[index reset CountiesIndex --reindex])
        }.to raise_error(ArgumentError, 'You cannot use --import and --reindex together')
      end

      it 'raises an error if --import and --reindex are used together' do
        expect {
          cli_exec(%w[index reset CountiesIndex --import --reindex])
        }.to raise_error(ArgumentError, 'You cannot use --import and --reindex together')
      end

      it 'forwards the --reindex option to the index class' do
        expect(CountiesIndex).to receive(:reset_index).with(**defaults, import: false, reindex: true).and_return(true)
        cli_exec(%w[index reset CountiesIndex --reindex --import=false])
      end

      it 'forwards the --import hash option to the index class' do
        expect(CountiesIndex).to receive(:reset_index).with(**defaults, import: { lazy_document_attributes: true }).and_return(true)
        cli_exec(%w[index reset CountiesIndex --import=lazy_document_attributes:true])
      end
    end
  end
end
