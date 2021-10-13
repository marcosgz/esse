# frozen_string_literal: true

require 'spec_helper'
require 'support/cli_helpers'

RSpec.describe Esse::CLI::Index, type: :cli do
  describe '#update_aliases' do
    it 'raises an error if no index name is given' do
      expect {
        cli_exec(%w[index update_aliases])
      }.to raise_error(Esse::CLI::InvalidOption, /You must specify at least one index class/)
    end

    it 'raises an error if given argument is not a valid index class' do
      expect {
        cli_exec(%w[index update_aliases Esse::Config --suffix=20210901])
      }.to raise_error(Esse::CLI::InvalidOption, /Esse::Config must be a subclass of Esse::Index/)
    end

    it 'raises an error if given argument is not defined' do
      expect {
        cli_exec(%w[index update_aliases NotDefinedIndexName --suffix=20210901])
      }.to raise_error(Esse::CLI::InvalidOption, /Unrecognized index class: "NotDefinedIndexName"/)
    end

    context 'with a valid index name' do
      before do
        stub_index(:counties)
        stub_index(:cities)
      end

      specify do
        expect {
          cli_exec(%w[index update_aliases CountiesIndex])
        }.to raise_error(Esse::CLI::InvalidOption, /must specify a suffix/)
      end

      specify do
        expect(CountiesIndex).to receive(:elasticsearch).at_least(1).and_return(api = double)
        expect(api).to receive(:update_aliases!).with(suffix: 'foo').and_return(true)
        cli_exec(%w[index update_aliases CountiesIndex --suffix=foo])
      end


      it 'allows multiple indices' do
        expect(CountiesIndex).to receive(:elasticsearch).at_least(1).and_return(api1 = double)
        expect(CitiesIndex).to receive(:elasticsearch).at_least(1).and_return(api2 = double)
        expect(api1).to receive(:update_aliases!).with(suffix: '123').and_return(true)
        expect(api2).to receive(:update_aliases!).with(suffix: '123').and_return(true)
        cli_exec(%w[index update_aliases CountiesIndex CitiesIndex --suffix=123])
      end
    end
  end
end
