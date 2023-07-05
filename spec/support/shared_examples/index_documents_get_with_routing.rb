# frozen_string_literal: true

RSpec.shared_examples 'index.get with routing' do
  include_context 'with venues index definition'

  it 'returns the document the instance of Esse::Document with routing' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index
      VenuesIndex.import(refresh: true, routing: 'geo')

      doc = nil
      expect {
        doc = VenuesIndex.get(Esse::HashDocument.new(id: 1, routing: 'geo'))
      }.not_to raise_error
      expect(doc['_id']).to eq('1')
      expect(doc['_source']).to eq('name' => 'Gourmet Paradise')
    end
  end
end
