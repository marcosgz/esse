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
        expect(CountiesIndex).to receive(:elasticsearch).at_least(1).and_return(api = double)
        expect(api).to receive(:import!).and_return(true)
        cli_exec(%w[index import CountiesIndex])
      end

      specify do
        expect(CountiesIndex).to receive(:elasticsearch).at_least(1).and_return(api = double)
        expect(api).to receive(:import!).with(suffix: 'foo', context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --suffix=foo])
      end

      specify do
        expect(CitiesIndex).to receive(:elasticsearch).at_least(1).and_return(api = double)
        expect(api).to receive(:import!).with('city', suffix: 'foo', context: {}).and_return(true)
        cli_exec(%w[index import CitiesIndex --suffix=foo --repo=city])
      end

      specify do
        expect(CountiesIndex).to receive(:elasticsearch).at_least(1).and_return(api = double)
        expect(api).to receive(:import!).with(suffix: 'foo', context: {validate: 'email', file: 'test.csv'}).and_return(true)
        cli_exec(%w[index import CountiesIndex --suffix=foo --context=validate:email file:test.csv])
      end

      it 'allows multiple indices' do
        expect(CountiesIndex).to receive(:elasticsearch).at_least(1).and_return(api1 = double)
        expect(CitiesIndex).to receive(:elasticsearch).at_least(1).and_return(api2 = double)
        expect(api1).to receive(:import!).and_return(true)
        expect(api2).to receive(:import!).and_return(true)
        cli_exec(%w[index import CountiesIndex CitiesIndex])
      end
    end
  end
end
