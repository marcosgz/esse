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
        stub_index(:counties)
        stub_index(:cities)
      end

      specify do
        expect(CountiesIndex).to receive(:elasticsearch).twice.and_return(api = double)
        expect(api).to receive(:index_name).with(suffix: nil).and_return('esse_counties_index_123')
        expect(api).to receive(:update_mapping!).and_return(true)
        cli_exec(%w[index update_mapping CountiesIndex])
      end

      specify do
        expect(CountiesIndex).to receive(:elasticsearch).twice.and_return(api = double)
        expect(api).to receive(:index_name).with(suffix: 'foo').and_return('esse_counties_index_foo')
        expect(api).to receive(:update_mapping!).with(suffix: 'foo').and_return(true)
        cli_exec(%w[index update_mapping CountiesIndex --suffix=foo])
      end


      it 'allows multiple indices' do
        expect(CountiesIndex).to receive(:elasticsearch).twice.and_return(api1 = double)
        expect(CitiesIndex).to receive(:elasticsearch).twice.and_return(api2 = double)
        expect(api1).to receive(:index_name).with(suffix: nil).and_return('esse_counties_index_123')
        expect(api1).to receive(:update_mapping!).and_return(true)
        expect(api2).to receive(:index_name).with(suffix: nil).and_return('esse_cities_index_123')
        expect(api2).to receive(:update_mapping!).and_return(true)
        cli_exec(%w[index update_mapping CountiesIndex CitiesIndex])
      end
    end

    context 'with a valid index name with types' do
      before do
        stub_index(:geos) do
          define_type :city
          define_type :county
        end
      end

      specify do
        expect(GeosIndex).to receive(:elasticsearch).at_least(2).and_return(api = double)
        expect(api).to receive(:index_name).twice.with(suffix: nil).and_return('esse_geos_index_123')
        expect(api).to receive(:update_mapping!).with(type: 'city').and_return(true)
        expect(api).to receive(:update_mapping!).with(type: 'county').and_return(true)
        cli_exec(%w[index update_mapping GeosIndex])
      end

      specify do
        expect(GeosIndex).to receive(:elasticsearch).at_least(2).and_return(api = double)
        expect(api).to receive(:index_name).twice.with(suffix: 'foo').and_return('esse_geos_index_foo')
        expect(api).to receive(:update_mapping!).with(type: 'city', suffix: 'foo').and_return(true)
        expect(api).to receive(:update_mapping!).with(type: 'county', suffix: 'foo').and_return(true)
        cli_exec(%w[index update_mapping GeosIndex --suffix=foo])
      end
    end
  end
end
