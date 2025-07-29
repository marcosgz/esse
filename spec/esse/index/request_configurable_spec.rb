# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index, 'RequestConfigurable' do
  before do
    reset_config!
  end

  describe ".combined_request_params_for?" do
    let(:index) { Class.new(Esse::Index) }

    context "when both index and cluster have request params for the operation" do
      it "returns false" do
        expect(index.combined_request_params_for?(:update)).to be false
      end
    end

    context "when index has request params for the operation" do
      before do
        index.request_params(:update, refresh: true)
      end

      it "returns true" do
        expect(index.combined_request_params_for?(:update)).to be true
      end
    end

    context "when cluster has request params for the operation" do
      before do
        index.cluster.request_params(:update, refresh: true)
      end

      it "returns true" do
        expect(index.combined_request_params_for?(:update)).to be true
      end
    end
  end


  describe ".combined_request_params_for" do
    let(:index) { Class.new(Esse::Index) }
    let(:doc) { instance_double(Esse::Document) }

    context "when both index and cluster have request params for the operation" do
      before do
        index.request_params(:update, refresh: true)
        index.cluster.request_params(:update, timeout: '5s', refresh: false)
      end

      it "returns merged request params" do
        expect(index.combined_request_params_for(:update, doc)).to eq(refresh: true, timeout: '5s')
      end
    end

    context "when index has request params for the operation" do
      before do
        index.request_params(:update, refresh: true)
      end

      it "returns index request params" do
        expect(index.combined_request_params_for(:update, doc)).to eq(refresh: true)
      end
    end

    context "when cluster has request params for the operation" do
      before do
        index.cluster.request_params(:update, timeout: '5s')
      end

      it "returns cluster request params" do
        expect(index.combined_request_params_for(:update, doc)).to eq(timeout: '5s')
      end
    end

    context "when neither index nor cluster have request params for the operation" do
      it "returns an empty hash" do
        expect(index.combined_request_params_for(:update, doc)).to eq({})
      end
    end
  end
end
