# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::IndexType do
  describe '.serializer' do
    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::IndexType) do
          serializer do
          end
        end
      }.not_to raise_error
      expect(klass.instance_variable_get(:@serializer_proc)).to be_a_kind_of(Proc)
    end

    specify do
      expect {
        Class.new(Esse::IndexType) do
          serializer
        end
      }.to raise_error(ArgumentError, 'nil is not a valid serializer. The serializer should respond with `as_json` instance method.')
    end

    specify do
      expect {
        Class.new(Esse::IndexType) do
          serializer :invalid
        end
      }.to raise_error(ArgumentError, ':invalid is not a valid serializer. The serializer should respond with `as_json` instance method.')
    end

    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::IndexType) do
          serializer(Class.new { def as_json; end; })
        end
      }.not_to raise_error
      expect(klass.instance_variable_get(:@serializer_proc)).to be_a_kind_of(Proc)
    end

    specify do
      klass = nil
      expect {
        klass = Class.new(Esse::IndexType) do
          serializer(Class.new { def call; end; })
        end
      }.not_to raise_error
      expect(klass.instance_variable_get(:@serializer_proc)).to be_a_kind_of(Proc)
    end
  end
end
