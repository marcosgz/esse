# frozen_string_literal: true

require 'spec_helper'
require 'support/cli_helpers'

RSpec.describe Esse::CLI::Index, type: :cli do
  describe '#update_mapping' do
    it 'raises an error if no index name is given' do
      expect {
        cli_exec(%w[index update_mapping])
      }.to raise_error(Esse::CLI::InvalidOption, /You must specify at least one index class/)
    end

    it 'raises an error if given argument is not a valid index class' do
      expect {
        cli_exec(%w[index update_mapping Esse::Config])
      }.to raise_error(Esse::CLI::InvalidOption, /Esse::Config must be a subclass of Esse::Index/)
    end

    it 'raises an error if given argument is not defined' do
      expect {
        cli_exec(%w[index update_mapping NotDefinedIndexName])
      }.to raise_error(Esse::CLI::InvalidOption, /Unrecognized index class: "NotDefinedIndexName"/)
    end

    context 'with a valid index name' do
      before do
        stub_index(:counties) do
          self.mapping_single_type = true
        end
        stub_index(:cities) do
          self.mapping_single_type = true
        end
      end

      specify do
        expect(CountiesIndex).to receive(:update_mapping).and_return(true)
        cli_exec(%w[index update_mapping CountiesIndex])
      end

      specify do
        expect(CountiesIndex).to receive(:update_mapping).with(suffix: 'foo').and_return(true)
        cli_exec(%w[index update_mapping CountiesIndex --suffix=foo])
      end

      it 'allows multiple indices' do
        expect(CountiesIndex).to receive(:update_mapping).and_return(true)
        expect(CitiesIndex).to receive(:update_mapping).and_return(true)
        cli_exec(%w[index update_mapping CountiesIndex CitiesIndex])
      end
    end

    context 'with a valid index name with types' do
      before do
        stub_index(:geos) do
          self.mapping_single_type = false
          repository :city
          repository :county
        end
      end

      specify do
        expect(GeosIndex).to receive(:update_mapping).with(type: 'city').and_return(true)
        expect(GeosIndex).to receive(:update_mapping).with(type: 'county').and_return(true)
        cli_exec(%w[index update_mapping GeosIndex])
      end

      specify do
        expect(GeosIndex).to receive(:update_mapping).with(type: 'city', suffix: 'foo').and_return(true)
        expect(GeosIndex).to receive(:update_mapping).with(type: 'county', suffix: 'foo').and_return(true)
        cli_exec(%w[index update_mapping GeosIndex --suffix=foo])
      end
    end
  end
end
