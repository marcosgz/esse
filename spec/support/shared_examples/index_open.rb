# frozen_string_literal: true

RSpec.shared_examples 'index.open' do
  include_context 'with venues index definition'

  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |client, _conf, cluster|
      expect {
        VenuesIndex.open(suffix: index_suffix)
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'opens the aliased index' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: true, suffix: index_suffix)
      cluster.wait_for_status!(index: VenuesIndex.index_name(suffix: index_suffix))
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        sleep(1)
      end
      VenuesIndex.close(suffix: index_suffix)
      cluster.wait_for_status!(index: VenuesIndex.index_name(suffix: index_suffix))
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        sleep(1)
      end

      resp = nil
      expect {
        resp = VenuesIndex.open
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
    end
  end

  it 'opens the unaliased index' do |example|
    es_client do |client, _conf, cluster|
      VenuesIndex.create_index(alias: false, suffix: index_suffix)
      cluster.wait_for_status!(index: VenuesIndex.index_name(suffix: index_suffix))
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        sleep(1)
      end
      VenuesIndex.close(suffix: index_suffix)
      cluster.wait_for_status!(index: VenuesIndex.index_name(suffix: index_suffix))
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        sleep(1)
      end

      resp = nil
      expect {
        resp = VenuesIndex.open(suffix: index_suffix)
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
    end
  end
end
