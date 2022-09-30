# frozen_string_literal: true

RSpec.shared_examples "cluster_api#health" do
  it 'retrieves the health of cluster' do
    es_client do |client, _conf, cluster|

      expect(resp = cluster.api.health).to be_a(Hash)
      expect(resp).to have_key('status')
    end
  end
end
