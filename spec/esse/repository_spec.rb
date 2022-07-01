# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Repository do
  describe '.backend' do
    specify do
      c = Class.new(described_class)
      expect(c.backend).to be_an_instance_of(Esse::Backend::RepositoryBackend)
    end
  end

  describe '.elasticsearch' do
    specify do
      c = Class.new(described_class)
      expect(c.elasticsearch).to be_an_instance_of(Esse::Backend::RepositoryBackend)
    end
  end
end
