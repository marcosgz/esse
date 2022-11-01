# frozen_string_literal: true

RSpec.shared_examples "cluster_api#open" do
  it "raises an Esse::Transport::ServerError exception when api throws an error" do
    es_client do |client, _conf, cluster|
      expect{
        cluster.api.open(index: 'esse_unknow_index_name_v1')
      }.to raise_error(Esse::Transport::ServerError)
    end
  end

  it 'opens an index' do
    es_client do |client, _conf, cluster|
      index_name = "#{cluster.index_prefix}_dummies_#{Esse.timestamp}"
      cluster.api.create_index(index: index_name, body: {
        settings: { number_of_shards: 1, number_of_replicas: 0 },
      })
      cluster.wait_for_status!(index: index_name)
      cluster.api.close(index: index_name)
      cluster.wait_for_status!(index: index_name)

      resp = nil
      expect {
        resp = cluster.api.open(index: index_name)
      }.not_to raise_error
      expect(resp['acknowledged']).to eq(true)
    end
  end
end
