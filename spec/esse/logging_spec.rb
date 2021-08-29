# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Logging do
  describe '.logger' do
    it { expect(Esse).to respond_to(:logger) }

    it { expect(Esse.logger).to be_an_instance_of(Logger) }
  end

  describe '.logger=' do
    it { expect(Esse).to respond_to(:logger=) }

    it 'sets the logger' do
      expected = Logger.new(STDOUT)
      expect {
        Esse.logger = expected
      }.to change { Esse.logger }
      expect(Esse.logger).to eq(expected)
      Esse.logger = nil
      expect(Esse.logger).to be_an_instance_of(Logger)
    end
  end
end
