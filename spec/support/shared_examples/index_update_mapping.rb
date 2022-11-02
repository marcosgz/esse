# frozen_string_literal: true

RSpec.shared_examples 'index.update_mapping' do
  include_context 'with geos index definition'

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.update_mapping(suffix: '2022')
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'update mappings from index definition' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: '2022')

      GeosIndex.mappings do
        {
          properties: {
            new_field: { type: 'text' }
          }
        }
      end

      resp = nil
      expect {
        resp = GeosIndex.update_mapping(suffix: '2022')
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)

      mapping = client.indices.get_mapping(index: index_name = GeosIndex.index_name(suffix: '2022'))
      expect(mapping.dig(index_name, 'mappings', 'properties', 'new_field')).to eq(
        'type' => 'text',
      )
    end
  end

  it 'update mappings from body argument' do
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: '2022')

      resp = nil
      expect {
        resp = GeosIndex.update_mapping(suffix: '2022', body: {
          properties: {
            new_field: { type: 'text' }
          }
        })
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)

      mapping = client.indices.get_mapping(index: index_name = GeosIndex.index_name(suffix: '2022'))
      expect(mapping.dig(index_name, 'mappings', 'properties', 'new_field')).to eq(
        'type' => 'text',
      )
    end
  end
end
