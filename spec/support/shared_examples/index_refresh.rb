# frozen_string_literal: true

RSpec.shared_examples 'index.refresh' do
  include_context 'with venues index definition'

  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.refresh(suffix: index_suffix)
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'refreshes the aliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true, suffix: index_suffix)

      resp = nil
      expect {
        resp = VenuesIndex.refresh
      }.not_to raise_error
      expect(resp).to be_a(Hash)
    end
  end

  it 'refreshes the unaliased index' do
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: index_suffix)

      resp = nil
      expect {
        resp = VenuesIndex.refresh(suffix: index_suffix)
      }.not_to raise_error
      expect(resp).to be_a(Hash)
    end
  end
end
