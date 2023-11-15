# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Search::Query, 'dsl' do
  describe '#limit_value' do
    subject { described_class.new(Class.new(Esse::Index), **params).limit_value }

    let(:params) { {} }

    it 'returns 10 by default' do
      is_expected.to eq(10)
    end

    context 'when definition have [:body][:size] value' do
      let(:params) do
        {
          body: {
            size: 100
          }
        }
      end

      it { is_expected.to eq(100) }
    end

    context 'when definition have [:body]["size"] value' do
      let(:params) do
        {
          body: {
            'size' => 100
          }
        }
      end

      it { is_expected.to eq(100) }
    end

    context 'when params have the :size' do
      let(:params) { { size: 20 } }

      it { is_expected.to eq(20) }
    end
  end

  describe '#offset_value' do
    subject { described_class.new(Class.new(Esse::Index), **params).offset_value }

    let(:params) { {} }

    it 'returns 0 by default' do
      is_expected.to eq(0)
    end

    context 'when definition have [:body][:from] value' do
      let(:params) do
        {
          body: {
            from: 100
          }
        }
      end

      it { is_expected.to eq(100) }
    end

    context 'when definition have [:body]["from"] value' do
      let(:params) do
        {
          body: {
            'from' => 100
          }
        }
      end

      it { is_expected.to eq(100) }
    end

    context 'when params have the :from' do
      let(:params) { { from: 20 } }

      it { is_expected.to eq(20) }
    end
  end

  describe '#raw_limit_value' do
    subject { described_class.new(Class.new(Esse::Index), **params).send(:raw_limit_value) }

    let(:params) { {} }

    it { is_expected.to eq(nil) }

    context 'when definition have [:body][:size] value' do
      let(:params) do
        {
          body: {
            size: 10
          }
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when definition have [:body]["size"] value' do
      let(:params) do
        {
          body: {
            'size' => 10
          }
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when params have the :size' do
      let(:params) { { size: 20 } }

      it { is_expected.to eq(20) }
    end
  end

  describe '#limit' do
    let(:query) { described_class.new(Class.new(Esse::Index), **params) }
    let(:params) { {} }

    it 'returns a new query' do
      expect { query.limit(20) }.not_to change { query.definition }
      expect(query.limit(20)).to be_a(described_class)
    end

    it 'sets the limit value' do
      expect(query.limit(20).limit_value).to eq(20)
    end

    it 'sets the limit value as an integer' do
      expect(query.limit('20').limit_value).to eq(20)
    end

    it 'returns self when the limit is less than 0' do
      expect(query.limit(-1)).to eq(query)
    end

    it 'returns self when the limit is 0' do
      expect(query.limit(0)).to eq(query)
    end

    context 'when definition have [:body][:size] value' do
      let(:params) do
        {
          body: {
            size: 10
          }
        }
      end

      it 'updates the definition' do
        expect(query.limit(20).definition).to eq(
          body: {
            size: 20
          }
        )
      end
    end

    context 'when definition have [:body]["size"] value' do
      let(:params) do
        {
          body: {
            'size' => 10
          }
        }
      end

      it 'updates the definition' do
        expect(query.limit(20).definition).to eq(
          body: {
            'size' => 20
          }
        )
      end
    end

    context 'when params have the :size' do
      let(:params) { { size: 20 } }

      it 'updates the definition' do
        expect(query.limit(10).definition).to eq(
          size: 10
        )
      end
    end

    context 'when params have the :size and definition have [:body][:size] value' do
      let(:params) do
        {
          size: 30,
          body: {
            size: 40
          }
        }
      end

      it 'updates the definition' do
        expect(query.limit(20).definition).to eq(
          body: {
            size: 20
          }
        )
      end
    end
  end

  describe '#offset' do
    let(:query) { described_class.new(Class.new(Esse::Index), **params) }
    let(:params) { {} }

    it 'returns a new query' do
      expect { query.offset(20) }.not_to change { query.definition }
      expect(query.offset(20)).to be_a(described_class)
    end

    it 'sets the offset value' do
      expect(query.offset(20).offset_value).to eq(20)
    end

    it 'sets the offset value as an integer' do
      expect(query.offset('20').offset_value).to eq(20)
    end

    it 'returns self when the offset is less than 0' do
      expect(query.offset(-1)).to eq(query)
    end

    context 'when definition have [:body][:from] value' do
      let(:params) do
        {
          body: {
            from: 10
          }
        }
      end

      it 'updates the definition' do
        expect(query.offset(20).definition).to eq(
          body: {
            from: 20
          }
        )
      end
    end

    context 'when definition have [:body]["from"] value' do
      let(:params) do
        {
          body: {
            'from' => 10
          }
        }
      end

      it 'updates the definition' do
        expect(query.offset(20).definition).to eq(
          body: {
            'from' => 20
          }
        )
      end
    end

    context 'when params have the :from' do
      let(:params) { { from: 20 } }

      it 'updates the definition' do
        expect(query.offset(10).definition).to eq(
          from: 10
        )
      end
    end

    context 'when params have the :from and definition have [:body][:from] value' do
      let(:params) do
        {
          from: 30,
          body: {
            from: 40
          }
        }
      end

      it 'updates the definition' do
        expect(query.offset(20).definition).to eq(
          body: {
            from: 20
          }
        )
      end
    end
  end

  describe '#raw_offset_value' do
    subject { described_class.new(Class.new(Esse::Index), **params).send(:raw_offset_value) }

    let(:params) { {} }

    it { is_expected.to eq(nil) }

    context 'when definition have [:body][:from] value' do
      let(:params) do
        {
          body: {
            from: 10
          }
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when definition have [:body]["from"] value' do
      let(:params) do
        {
          body: {
            'from' => 10
          }
        }
      end

      it { is_expected.to eq(10) }
    end

    context 'when params have the :from' do
      let(:params) { { from: 20 } }

      it { is_expected.to eq(20) }
    end
  end
end
