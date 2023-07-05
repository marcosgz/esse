# frozen_string_literal: true

RSpec.shared_examples 'transport#health' do
  it 'retrieves the health of cluster' do
    es_client do |_client, _conf, cluster|
      expect(resp = cluster.api.health).to be_a(Hash)
      expect(resp).to have_key('status')
    end
  end

  it 'does not raise Esse::Transport::ReadonlyClusterError error when the cluster is readonly' do
    es_client do |_client, _conf, cluster|
      cluster.readonly = true
      expect {
        cluster.api.health
      }.not_to raise_error
    end
  end
end
