# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Cluster, '.search' do
  describe '.search' do
    specify do
      c = described_class.new(id: :v1)
      expect(c.search).to be_an_instance_of(Esse::Search::Query)
    end
  end
end
