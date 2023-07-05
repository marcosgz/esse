# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable convention:RSpec/FilePath
RSpec.describe Esse::Serializer, 'deprecations' do
  it 'inherits from Esse::Document' do
    klass = Gem::Deprecate.skip_during do
      Class.new(Esse::Serializer)
    end

    expect(klass).to be < Esse::Document
    expect(klass.new(double)).to be_a(Esse::Document)
  end

  it 'should be considered a valid document' do
    klass = Gem::Deprecate.skip_during do
      Class.new(Esse::Serializer) do
        def id
          1
        end
      end
    end
    doc = klass.new(double, foo: :bar)

    expect(Esse.document?(doc)).to eq(true)
  end
end
