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
      before do
        stub_index(:counties)
        stub_index(:cities)
      end

      specify do
        expect(CountiesIndex).to receive(:reset_index).and_return(true)
        cli_exec(%w[index reset CountiesIndex])
      end

      specify do
        expect(CountiesIndex).to receive(:reset_index).with(suffix: 'foo', import: true).and_return(true)
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
    end
  end
end
