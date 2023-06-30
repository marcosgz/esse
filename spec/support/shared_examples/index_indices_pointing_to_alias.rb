# frozen_string_literal: true

RSpec.shared_examples 'index.indices_pointing_to_alias' do
  include_context 'with geos index definition'

  it 'retrieves the aliases for the given index' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: '2022')

      expect(GeosIndex.indices_pointing_to_alias).to eq(["#{GeosIndex.index_name}_2022"])
    end
  end

  it 'returns an empty array when it was created without alias' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: '2022')

      expect(GeosIndex.indices_pointing_to_alias).to eq([])
    end
  end

  it "returns an empty array when the index doesn't exist" do
    expected_value = nil

    es_client do |client, _conf, cluster|
      expect {
        expected_value = GeosIndex.indices_pointing_to_alias
      }.not_to raise_error
    end

    expect(expected_value).to eq([])
  end
end
