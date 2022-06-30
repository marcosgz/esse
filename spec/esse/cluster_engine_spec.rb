# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::ClusterEngine do
  let(:model) { described_class.new(**info) }
  let(:service_version) { '7.0.0' }
  let(:service_name) { 'elasticsearch' }
  let(:info) do
    {
      version: service_version,
      distribution: service_name,
    }
  end

  shared_examples 'a cluster engine' do
    specify do
      expect(model.version).to eq(service_version)
    end

    specify do
      expect(model.distribution).to eq(service_name)
    end
  end

  it_behaves_like 'a cluster engine' do
    let(:service_version) { '1.0.0' }
    let(:service_name) { 'elasticsearch' }

    it { expect(model).to be_elasticsearch }
    it { expect(model).not_to be_opensearch }
    it { expect(model).not_to be_mapping_single_type }
  end

  it_behaves_like 'a cluster engine' do
    let(:service_version) { '2.0.0' }
    let(:service_name) { 'elasticsearch' }

    it { expect(model).to be_elasticsearch }
    it { expect(model).not_to be_opensearch }
    it { expect(model).not_to be_mapping_single_type }
  end

  it_behaves_like 'a cluster engine' do
    let(:service_version) { '5.0.0' }
    let(:service_name) { 'elasticsearch' }

    it { expect(model).to be_elasticsearch }
    it { expect(model).not_to be_opensearch }
    it { expect(model).not_to be_mapping_single_type }
  end

  it_behaves_like 'a cluster engine' do
    let(:service_version) { '6.0.0' }
    let(:service_name) { 'elasticsearch' }

    it { expect(model).to be_elasticsearch }
    it { expect(model).not_to be_opensearch }
    it { expect(model).to be_mapping_single_type }
  end

  it_behaves_like 'a cluster engine' do
    let(:service_version) { '7.0.0' }
    let(:service_name) { 'elasticsearch' }

    it { expect(model).to be_elasticsearch }
    it { expect(model).not_to be_opensearch }
    it { expect(model).to be_mapping_single_type }
  end

  it_behaves_like 'a cluster engine' do
    let(:service_version) { '8.0.0' }
    let(:service_name) { 'elasticsearch' }

    it { expect(model).to be_elasticsearch }
    it { expect(model).not_to be_opensearch }
    it { expect(model).to be_mapping_single_type }
  end

  it_behaves_like 'a cluster engine' do
    let(:service_version) { '1.0.0' }
    let(:service_name) { 'opensearch' }

    it { expect(model).not_to be_elasticsearch }
    it { expect(model).to be_opensearch }
    it { expect(model).to be_mapping_single_type }
  end

  it_behaves_like 'a cluster engine' do
    let(:service_version) { '2.0.0' }
    let(:service_name) { 'opensearch' }

    it { expect(model).not_to be_elasticsearch }
    it { expect(model).to be_opensearch }
    it { expect(model).to be_mapping_single_type }
  end
end
