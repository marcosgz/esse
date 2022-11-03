# frozen_string_literal: true

require 'spec_helper'
require 'support/cli_helpers'

RSpec.describe Esse::CLI::Index, type: :cli do
  describe '#close' do
    it 'raises an error if no index name is given' do
      expect {
        cli_exec(%w[index close])
      }.to raise_error(Esse::CLI::InvalidOption, /You must specify at least one index class/)
    end

    it 'raises an error if given argument is not a valid index class' do
      expect {
        cli_exec(%w[index close Esse::Config])
      }.to raise_error(Esse::CLI::InvalidOption, /Esse::Config must be a subclass of Esse::Index/)
    end

    it 'raises an error if given argument is not defined' do
      expect {
        cli_exec(%w[index close NotDefinedIndexName])
      }.to raise_error(Esse::CLI::InvalidOption, /Unrecognized index class: "NotDefinedIndexName"/)
    end

    context 'with a valid index name' do
      before do
        stub_index(:counties)
        stub_index(:cities)
      end

      specify do
        expect(CountiesIndex).to receive(:close).and_return(true)
        cli_exec(%w[index close CountiesIndex])
      end

      specify do
        expect(CountiesIndex).to receive(:close).with(suffix: 'foo').and_return(true)
        cli_exec(%w[index close CountiesIndex --suffix=foo])
      end


      it 'allows multiple indices' do
        expect(CountiesIndex).to receive(:close).and_return(true)
        expect(CitiesIndex).to receive(:close).and_return(true)
        cli_exec(%w[index close CountiesIndex CitiesIndex])
      end
    end
  end
end
