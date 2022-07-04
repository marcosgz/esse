# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index, '.search' do
  describe '.search' do
    specify do
      c = Class.new(Esse::Index)
      expect(c.search).to be_an_instance_of(Esse::Search::Query)
    end
  end
end
