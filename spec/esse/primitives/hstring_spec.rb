# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Hstring do
  let(:model) { described_class.new(arg) }

  describe '.underscore' do
    subject { model.underscore }

    context 'with capitalized string' do
      let(:arg) { 'User' }

      it { is_expected.to eq('user') }
    end

    context 'with camelized string' do
      let(:arg) { 'UserName' }

      it { is_expected.to eq('user_name') }
    end

    context 'with camelized string' do
      let(:arg) { 'UserName' }

      it { is_expected.to eq('user_name') }
    end

    context 'with parameterized string' do
      let(:arg) { 'foo-bar' }

      it { is_expected.to eq('foo_bar') }
    end
  end

  describe '.demodulize' do
    subject { model.demodulize }

    context 'with single class' do
      let(:arg) { 'User' }

      it { is_expected.to eq('User') }
    end

    context 'with only one level modulized string' do
      let(:arg) { '::User' }

      it { is_expected.to eq('User') }
    end

    context 'with multiple modulized string' do
      let(:arg) { '::Foo::Bar' }

      it { is_expected.to eq('Bar') }
    end
  end

  describe '.modulize' do
    subject { model.modulize }

    context 'delimited by backslashes' do
      let(:arg) { 'foo\bar' }

      it { is_expected.to eq('Foo::Bar') }
    end

    context 'delimited by forward slashes' do
      let(:arg) { 'foo/bar' }

      it { is_expected.to eq('Foo::Bar') }
    end

    context 'modulized like argument' do
      let(:arg) { 'Foo::bar_baz' }

      it { is_expected.to eq('Foo::BarBaz') }
    end
  end

  describe '.camelize' do
    subject { model.camelize }

    context 'with a symbol' do
      let(:arg) { :user }

      it { is_expected.to eq('User') }
    end

    context 'with snake string' do
      let(:arg) { 'user_index' }

      it { is_expected.to eq('UserIndex') }
    end

    context 'with partial upercased string' do
      let(:arg) { 'userIndex' }

      it { is_expected.to eq('UserIndex') }
    end
  end

  describe '.presence' do
    subject { model.presence }

    context 'with a empty string' do
      let(:arg) { '' }

      it { is_expected.to eq(nil) }
    end

    context 'with a nil value' do
      let(:arg) { nil }

      it { is_expected.to eq(nil) }
    end

    context 'when the value is not blank' do
      let(:arg) { 'a' }

      it { is_expected.to eq('a') }
    end
  end
end
