# frozen_string_literal: true

require 'spec_helper'
require 'esse/cli'

RSpec.describe Esse::CLI::Parser::BoolOrHash do
  describe '#parse' do
    let(:options) { {} }
    let(:key) { :testkey }

    context 'when passing a boolean' do
      let(:parser) { described_class.new(key, **options) }

      it { expect(parser.parse('true')).to eq(true) }
      it { expect(parser.parse('TRUE')).to eq(true) }
      it { expect(parser.parse('t')).to eq(true) }
      it { expect(parser.parse('T')).to eq(true) }
      it { expect(parser.parse(true)).to eq(true) }

      it { expect(parser.parse('false')).to eq(false) }
      it { expect(parser.parse('FALSE')).to eq(false) }
      it { expect(parser.parse('f')).to eq(false) }
      it { expect(parser.parse('F')).to eq(false) }
      it { expect(parser.parse(false)).to eq(false) }
    end

    context 'when passing a string' do
      let(:parser) { described_class.new(key, **options) }

      it { expect(parser.parse('foo')).to eq(nil) }
      it { expect(parser.parse('')).to eq(nil) }
      it { expect(parser.parse(nil)).to eq(nil) }

      it "returns true when the key is the same as the input" do
        expect(parser.parse(key.to_s)).to eq(true)
      end
    end

    context 'when passing true as default' do
      let(:parser) { described_class.new(key, default: true) }

      it { expect(parser.parse('foo')).to eq(true) }
      it { expect(parser.parse('')).to eq(true) }
      it { expect(parser.parse(nil)).to eq(true) }
      it { expect(parser.parse('true')).to eq(true) }
      it { expect(parser.parse('false')).to eq(false) }
    end

    context 'when passing false as default' do
      let(:parser) { described_class.new(key, default: false) }

      it { expect(parser.parse('foo')).to eq(false) }
      it { expect(parser.parse('')).to eq(false) }
      it { expect(parser.parse(nil)).to eq(false) }
      it { expect(parser.parse('true')).to eq(true) }
      it { expect(parser.parse('false')).to eq(false) }
    end

    context 'when passing a hash as default' do
      let(:parser) { described_class.new(key, default: { foo: 'bar' }) }

      it { expect(parser.parse('foo')).to eq(foo: 'bar') }
      it { expect(parser.parse('')).to eq(foo: 'bar') }
      it { expect(parser.parse(nil)).to eq(foo: 'bar') }
      it { expect(parser.parse('true')).to eq(true) }
      it { expect(parser.parse('false')).to eq(false) }
    end

    context 'when passing a hash' do
      let(:parser) { described_class.new(key, **options) }

      it { expect(parser.parse('foo:bar')).to eq(foo: 'bar') }
      it { expect(parser.parse('f_o:bar')).to eq(f_o: 'bar') }
      it { expect(parser.parse('f0o:bar')).to eq(f0o: 'bar') }
      it { expect(parser.parse('f-o:bar')).to eq('f-o': 'bar') }
      it { expect(parser.parse('foo:bar baz:qux')).to eq(foo: 'bar', baz: 'qux') }

      it 'explodes keys' do
        expect(parser.parse('a.b.c:d')).to eq(a: { b: { c: 'd' } })
        expect(parser.parse('a.b.c:d a.b.x:y')).to eq(a: { b: { c: 'd', x: 'y' } })
      end

      it 'split comma separated values' do
        expect(parser.parse('a:c,d,e')).to eq(a: %w[c d e])
        expect(parser.parse('a:x,y,z b:p,q,r')).to eq(a: %w[x y z], b: %w[p q r])
        expect(parser.parse('a:b,c:d')).to eq(a: %w[b c:d])
      end

      it 'returns the given value when it is already a hash' do
        expect(parser.parse(foo: 'bar')).to eq(foo: 'bar')
      end

      it 'coerces the value of hash to boolean' do
        expect(parser.parse('foo:true')).to eq(foo: true)
        expect(parser.parse('foo:false')).to eq(foo: false)
      end

      it 'coerces the value of hash to integer' do
        expect(parser.parse('foo:123')).to eq(foo: 123)
      end

      it 'coerces the value of hash to float' do
        expect(parser.parse('foo:123.456')).to eq(foo: 123.456)
      end
    end
  end
end
