# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Config do
  let(:model) { described_class.new }

  describe '.cluster_ids' do
    specify do
      expect(model.cluster_ids).to match_array(%i[default])

      model.clusters(:v1) {}
      expect(model.cluster_ids).to match_array(%i[default v1])

      model.clusters('v1') {}
      expect(model.cluster_ids).to match_array(%i[default v1])

      model.clusters('v2') {}
      expect(model.cluster_ids).to match_array(%i[default v1 v2])
    end
  end

  describe '.load' do
    Esse::Config::ATTRIBUTES.each do |name|
      context "with the #{name} writer attribute" do
        it 'allows a hash with string keys' do
          expect(model).to receive(:"#{name}=").and_return(true)

          model.load(name.to_s => true, 'other' => false)
        end

        it 'allows a hash with symbol keys' do
          expect(model).to receive(:"#{name}=").and_return(true)

          model.load(name.to_sym => true, :other => false)
        end
      end

      context 'with cluster write attribute' do
        it 'ignores objects different than Hash' do
          expect(model).not_to receive(:clusters)
          model.load(clusters: 'test', other: false)
          model.load('clusters' => 'test', :other => false)
          model.load(clusters: nil, other: false)
          model.load('clusters' => nil, :other => false)
          model.load(clusters: [], other: false)
          model.load('clusters' => [], :other => false)
        end

        it 'configures each cluster using key string as cluster id' do
          cluster = instance_double(Esse::Cluster, assign: true)
          expect(model).to receive(:clusters).with('v1').and_return(cluster)

          model.load(clusters: { 'v1' => { client: nil } }, other: false)
        end

        it 'configures each cluster using key symbol as cluster id' do
          cluster = instance_double(Esse::Cluster, assign: true)
          expect(model).to receive(:clusters).with(:v1).and_return(cluster)

          model.load(clusters: { v1: { client: nil } }, other: false)
        end
      end
    end
  end

  describe '.indices_directory' do
    it 'defaults to the app/indices' do
      expect(model.indices_directory).to eq(Pathname.new('app/indices'))
    end

    it 'wraps the string path to an instance of Pathname' do
      model.indices_directory = 'lib/indices'
      expect(model.indices_directory).to eq(Pathname.new('lib/indices'))
    end
  end
end
