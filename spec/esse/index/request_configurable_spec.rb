# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index, 'RequestConfigurable' do
  let(:index) { Class.new(Esse::Index) }

  before do
    reset_config!
  end
end
