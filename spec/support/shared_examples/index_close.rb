# frozen_string_literal: true

RSpec.shared_examples 'index.close' do
  include_context 'with geos index definition'

  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        GeosIndex.close(suffix: index_suffix)
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'closes the aliased index' do |example|
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: true, suffix: index_suffix)

      resp = nil
      expect {
        resp = GeosIndex.close
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
      unless %w[1.x 2.x 5.x 6.x].include?(example.metadata[:es_version])
        expect(resp.dig('indices', GeosIndex.index_name(suffix: index_suffix), 'closed')).to eq(true)
      end
    end
  end

  it 'closes the unaliased index' do |example|
    es_client do |client, _conf, cluster|
      GeosIndex.create_index(alias: false, suffix: index_suffix)
      cluster.wait_for_status!(index: GeosIndex.index_name(suffix: index_suffix))

      resp = nil
      expect {
        resp = GeosIndex.close(suffix: index_suffix)
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
      unless %w[1.x 2.x 5.x 6.x].include?(example.metadata[:es_version])
        expect(resp.dig('indices', GeosIndex.index_name(suffix: index_suffix), 'closed')).to eq(true)
      end
    end
  end
end
