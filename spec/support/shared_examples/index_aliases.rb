# frozen_string_literal: true

RSpec.shared_examples 'index.aliases' do
  include_context 'with venues index definition'

  let(:index_suffix) { SecureRandom.hex(8) }

  it 'retrieves the aliases for the given index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true, suffix: index_suffix)

      expect(VenuesIndex.aliases).to eq([VenuesIndex.index_name])
    end
  end

  it 'returns an empty array when the index was created without alias' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: index_suffix)

      expect(VenuesIndex.aliases).to eq([])
    end
  end

  it "returns an empty array when the index doesn't exist" do
    expected_value = nil

    es_client do |client, _conf, cluster|
      expect {
        expected_value = VenuesIndex.aliases
      }.not_to raise_error
    end

    expect(expected_value).to eq([])
  end
end
