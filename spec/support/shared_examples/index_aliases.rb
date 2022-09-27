# frozen_string_literal: true

RSpec.shared_examples "index.aliases" do
  it 'retrieves the aliases for the given index' do
    es_client do |client, _conf, cluster|
      GeosIndex.elasticsearch.create_index!(alias: true, suffix: "2022")

      expect(GeosIndex.aliases).to eq([GeosIndex.index_name])
    end
  end

  it "returns an empty array when the index was created without alias" do
    es_client do |client, _conf, cluster|
      GeosIndex.elasticsearch.create_index!(alias: false, suffix: "2022")

      expect(GeosIndex.aliases).to eq([])
    end
  end

  it "returns an empty array when the index doesn't exist" do
    expected_value = nil

    es_client do |client, _conf, cluster|
      expect{
        expected_value = GeosIndex.aliases
      }.not_to raise_error
    end

    expect(expected_value).to eq([])
  end
end
