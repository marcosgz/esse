# frozen_string_literal: true

RSpec.shared_examples 'cluster_api#close' do
  let(:index_suffix) { SecureRandom.hex(8) }

  it 'raises an Esse::Transport::ServerError exception when api throws an error' do
    es_client do |_client, _conf, cluster|
      expect {
        cluster.api.close(index: 'esse_unknow_index_name_v1')
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'closes an index' do |example|
    es_client do |_client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{index_suffix}"
      cluster.api.create_index(index: index_name, body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })

      cluster.wait_for_status!(index: index_name)
      if %w[1.x 2.x].include?(example.metadata[:es_version])
        sleep(1)
      end

      resp = nil
      expect {
        resp = cluster.api.close(index: index_name)
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
      unless %w[1.x 2.x 5.x 6.x].include?(example.metadata[:es_version])
        expect(resp.dig('indices', index_name, 'closed')).to eq(true)
      end
    end
  end
end
