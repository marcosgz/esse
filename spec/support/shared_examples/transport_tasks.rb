# frozen_string_literal: true

RSpec.shared_examples 'transport#tasks' do
  it 'retrieves the tasks of cluster' do
    es_client do |_client, _conf, cluster|
      expect(resp = cluster.api.tasks).to be_a(Hash)
      expect(resp).to have_key('nodes')
    end
  end

  it 'does not raise Esse::Transport::ReadonlyClusterError error when the cluster is readonly' do
    es_client do |_client, _conf, cluster|
      cluster.readonly = true
      expect {
        cluster.api.tasks
      }.not_to raise_error
    end
  end
end

RSpec.shared_examples 'transport#task' do
  it 'retrieves the task of cluster' do
    es_client do |_client, _conf, cluster|
      expect(cluster.client.tasks).to receive(:get).with(task_id: '1').and_return({ 'task' => { 'id' => '1' } })

      expect(resp = cluster.api.task(id: '1')).to be_a(Hash)
    end
  end
end

RSpec.shared_examples 'transport#cancel_task' do
  it 'cancels the task of cluster' do
    es_client do |_client, _conf, cluster|
      expect(cluster.client.tasks).to receive(:cancel).with(task_id: '1').and_return({ 'task' => { 'id' => '1' } })

      expect(resp = cluster.api.cancel_task(id: '1')).to be_a(Hash)
    end
  end
end
