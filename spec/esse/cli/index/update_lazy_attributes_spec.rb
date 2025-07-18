# frozen_string_literal: true

require 'spec_helper'
require 'support/cli_helpers'

RSpec.describe Esse::CLI::Index, type: :cli do
  describe "#update_lazy_attributes" do
    let(:index_collection_class) do
      Class.new(Esse::Collection) do
        def each_batch_ids
          yield([1, 2, 3])
        end
      end
    end

    after do
      reset_config!
    end

    context "when passing undefined or invalid index name" do
      it "raises an error if given argument is not a valid index class" do
        expect {
          cli_exec(%w[index update_lazy_attributes Esse::Config])
        }.to raise_error(Esse::CLI::InvalidOption, /Esse::Config must be a subclass of Esse::Index/)
      end

      it "raises an error if given argument is not defined" do
        expect {
          cli_exec(%w[index update_lazy_attributes NotDefinedIndexName])
        }.to raise_error(Esse::CLI::InvalidOption, /Unrecognized index class: "NotDefinedIndexName"/)
      end
    end


    context "when passing a valid index with single repository" do
      before do
        collection_class = index_collection_class
        stub_index(:cities) do
          repository :city do
            collection collection_class
            lazy_document_attribute :total_events do |docs|
              docs.map { |doc| [doc.id, 10] }.to_h
            end
            lazy_document_attribute :total_venues do |docs|
              docs.map { |doc| [doc.id, 20] }.to_h
            end
          end
        end
      end

      it "calls the update_documents_attribute method for each lazy attribute" do
        expect(CitiesIndex::City).to receive(:update_documents_attribute).with(:total_events, [1, 2, 3], {}).and_return(:ok)
        expect(CitiesIndex::City).to receive(:update_documents_attribute).with(:total_venues, [1, 2, 3], {}).and_return(:ok)

        cli_exec(%w[index update_lazy_attributes CitiesIndex])
      end

      it "calls the update_documents_attribute method with bulk options" do
        expect(CitiesIndex::City).to receive(:update_documents_attribute).with(:total_events, [1, 2, 3], {refresh: true, retry_on_conflict: 3, timeout: "30s"}).and_return(:ok)
        expect(CitiesIndex::City).to receive(:update_documents_attribute).with(:total_venues, [1, 2, 3], {refresh: true, retry_on_conflict: 3, timeout: "30s"}).and_return(:ok)

        cli_exec(%w[index update_lazy_attributes CitiesIndex --bulk-options=timeout:30s refresh:true retry_on_conflict:3])
      end

      it "calls the update_documents_attribute method with context options" do
        expect(CitiesIndex::City).to receive(:each_batch_ids).once.with(active: true).and_call_original
        expect(CitiesIndex::City).to receive(:update_documents_attribute).with(:total_events, [1, 2, 3], {}).and_return(:ok)
        expect(CitiesIndex::City).to receive(:update_documents_attribute).with(:total_venues, [1, 2, 3], {}).and_return(:ok)

        cli_exec(%w[index update_lazy_attributes CitiesIndex --context=active:true])
      end

      it "allows to specify lazy attributes to update" do
        expect(CitiesIndex::City).to receive(:update_documents_attribute).with(:total_events, [1, 2, 3], {}).and_return(:ok)
        expect(CitiesIndex::City).not_to receive(:update_documents_attribute).with(:total_venues, [1, 2, 3], {})

        cli_exec(%w[index update_lazy_attributes CitiesIndex total_events])
      end

      it "allows to specify index repository" do
        expect(CitiesIndex::City).to receive(:update_documents_attribute).with(:total_events, [1, 2, 3], {}).and_return(:ok)
        expect(CitiesIndex::City).not_to receive(:update_documents_attribute).with(:total_venues, [1, 2, 3], {})

        cli_exec(%w[index update_lazy_attributes CitiesIndex --repo=city total_events])
      end
    end
  end
end
