# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable convention:RSpec/FilePath
RSpec.describe Esse::Cluster, '.index_settings' do
  specify do
    Gem::Deprecate.skip_during do
      cluster = described_class.new(id: :test)
      expect(cluster).to respond_to(:index_settings)
      expect(cluster).to respond_to(:index_settings=)
      expect {
        cluster.index_settings = { number_of_replicas: 4 }
      }.to change { cluster.settings }.from({}).to(number_of_replicas: 4)
    end
  end
end

RSpec.describe Esse::Cluster, '.index_mappings' do
  specify do
    Gem::Deprecate.skip_during do
      cluster = described_class.new(id: :test)
      expect(cluster).to respond_to(:index_mappings)
      expect(cluster).to respond_to(:index_mappings=)
      expect {
        cluster.index_mappings = { dynamic_date_formats: ['MM/dd/yyyy'] }
      }.to change { cluster.mappings }.from({}).to(dynamic_date_formats: ['MM/dd/yyyy'])
    end
  end
end
# rubocop:enable convention:RSpec/FilePath
