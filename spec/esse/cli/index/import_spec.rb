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

      it 'allows to pass --eager-load-lazy-attributes without value' do
        expect(CountiesIndex).to receive(:import).with(eager_load_lazy_attributes: true, context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --eager-load-lazy-attributes])
      end

      it 'allows to pass --eager-load-lazy-attributes as true' do
        expect(CountiesIndex).to receive(:import).with(eager_load_lazy_attributes: true, context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --eager-load-lazy-attributes=true])
      end

      it 'allows to pass --eager-load-lazy-attributes as false' do
        expect(CountiesIndex).to receive(:import).with(context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --eager-load-lazy-attributes=false])
      end

      it 'allows to pass --eager-load-lazy-attributes as a single value' do
        expect(CountiesIndex).to receive(:import).with(eager_load_lazy_attributes: %w[foo], context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --eager-load-lazy-attributes=foo])
      end

      it 'allows to pass --eager-load-lazy-attributes as a comma separated list' do
        expect(CountiesIndex).to receive(:import).with(eager_load_lazy_attributes: %w[foo bar], context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --eager-load-lazy-attributes=foo,bar])
      end

      it 'allows to pass --update-lazy-attributes without value' do
        expect(CountiesIndex).to receive(:import).with(update_lazy_attributes: true, context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --update-lazy-attributes])
      end

      it 'allows to pass --update-lazy-attributes as true' do
        expect(CountiesIndex).to receive(:import).with(update_lazy_attributes: true, context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --update-lazy-attributes=true])
      end

      it 'allows to pass --update-lazy-attributes as false' do
        expect(CountiesIndex).to receive(:import).with(context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --update-lazy-attributes=false])
      end

      it 'allows to pass --update-lazy-attributes as a single value' do
        expect(CountiesIndex).to receive(:import).with(update_lazy_attributes: %w[foo], context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --update-lazy-attributes=foo])
      end

      it 'allows to pass --update-lazy-attributes as a comma separated list' do
        expect(CountiesIndex).to receive(:import).with(update_lazy_attributes: %w[foo bar], context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --update-lazy-attributes=foo,bar])
      end

      it 'allows to pass --preload-lazy-attributes without value' do
        expect(CountiesIndex).to receive(:import).with(preload_lazy_attributes: true, context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --preload-lazy-attributes])
      end

      it 'allows to pass --preload-laazy-attributes as true' do
        expect(CountiesIndex).to receive(:import).with(preload_lazy_attributes: true, context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --preload-lazy-attributes=true])
      end

      it 'allows to pass --preload-laazy-attributes as false' do
        expect(CountiesIndex).to receive(:import).with(context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --preload-lazy-attributes=false])
      end

      it 'allows to pass --preload-laazy-attributes as a single value' do
        expect(CountiesIndex).to receive(:import).with(preload_lazy_attributes: %w[foo], context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --preload-lazy-attributes=foo])
      end

      it 'allows to pass --preload-laazy-attributes as a comma separated list' do
        expect(CountiesIndex).to receive(:import).with(preload_lazy_attributes: %w[foo bar], context: {}).and_return(true)
        cli_exec(%w[index import CountiesIndex --preload-lazy-attributes=foo,bar])
      end
    end
  end
end
