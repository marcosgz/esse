# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Repository do
  describe '.action' do
    specify do
      expect {
        Class.new(Esse::Repository) do
          action :update do
          end
        end
      }.not_to raise_error
    end

    specify do
      expect {
        Class.new(Esse::Repository) do
          action :update, {} do
          end
        end
      }.not_to raise_error
    end
  end
end
