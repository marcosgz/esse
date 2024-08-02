# frozen_string_literal: true

require 'spec_helper'
require 'support/cli_helpers'

RSpec.describe Esse::CLI::Index, type: :cli do
  describe '#create' do
    it 'raises an error if no index name is given' do
      expect {
        cli_exec(%w[index create])
      }.to raise_error(Esse::CLI::InvalidOption, /You must specify at least one index class/)
    end

    it 'raises an error if given argument is not a valid index class' do
      expect {
        cli_exec(%w[index create Esse::Config])
      }.to raise_error(Esse::CLI::InvalidOption, /Esse::Config must be a subclass of Esse::Index/)
    end

    it 'raises an error if given argument is not defined' do
      expect {
        cli_exec(%w[index create NotDefinedIndexName])
      }.to raise_error(Esse::CLI::InvalidOption, /Unrecognized index class: "NotDefinedIndexName"/)
    end

    context 'with a valid index name' do
      before do
        stub_index(:counties)
        stub_index(:cities)
      end

      specify do
        expect(CountiesIndex).to receive(:create_index).with(alias: false).and_return(true)
        cli_exec(%w[index create CountiesIndex])
      end

      specify do
        expect(CountiesIndex).to receive(:create_index).with(suffix: 'foo', alias: false).and_return(true)
        cli_exec(%w[index create CountiesIndex --suffix=foo])
      end

      specify do
        expect(CountiesIndex).to receive(:create_index).with(alias: true).and_return(true)
        cli_exec(%w[index create CountiesIndex --alias])
      end

      it 'allows multiple indices' do
        expect(CountiesIndex).to receive(:create_index).with(alias: false).and_return(true)
        expect(CitiesIndex).to receive(:create_index).with(alias: false).and_return(true)
        cli_exec(%w[index create CountiesIndex CitiesIndex])
      end

      it 'allows to pass --settings as a hash with imploded values' do
        expect(CountiesIndex).to receive(:create_index).with(alias: false, settings: { 'index.refresh_interval': '1s' }).and_return(true)
        cli_exec(%w[index create CountiesIndex --settings=index.refresh_interval:1s])
      end
    end
  end
end
