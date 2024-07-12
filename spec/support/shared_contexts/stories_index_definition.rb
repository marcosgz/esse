# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.shared_context 'with stories index definition' do
  let(:nyt) do
    { id: 1, name: 'The New York Times', slug: 'nyt' }
  end
  let(:wsj) do
    { id: 2, name: 'The Wall Street Journal', slug: 'wsj' }
  end
  let(:nyt_stories) do
    [
      { id: 1_001, title: 'The first story', story: nyt, published_at: '2019-01-01', tags: %w[news politics], publication: 'nyt' },
      { id: 1_002, title: 'The second story', story: nyt, published_at: '2019-01-02', tags: %w[news], publication: 'nyt' },
      { id: 1_003, title: 'The third story', story: nyt, published_at: nil, tags: %w[news politics], publication: 'nyt' },
    ]
  end
  let(:wsj_stories) do
    [
      { id: 2_001, title: 'The first story', story: wsj, published_at: '2019-01-01', tags: %w[news politics], publication: 'wsj' },
      { id: 2_002, title: 'The second story', story: wsj, published_at: '2019-01-01', tags: %w[news], publication: 'wsj' },
      { id: 2_003, title: 'The third story', story: wsj, published_at: nil, tags: %w[news politics], publication: 'wsj' },
    ]
  end
  let(:publication_stories) do
    {
      nyt => nyt_stories,
      wsj => wsj_stories,
    }
  end
  let(:stories) { publication_stories.values.flatten }

  before do
    # closure for the stub_index block
    ds = stories

    stub_index(:stories) do
      repository :story do
        collection do |**context, &block|
          stories = context[:conditions] ? ds.select(&context[:conditions]) : ds
          block.call(stories, **context) unless stories.empty?
        end
        document do |story, **context|
          {
            _id: story[:id],
            _routing: story[:publication],
            publication: story[:publication],
            title: story[:title],
            published_at: story[:published_at],
          }
        end
        lazy_document_attribute :tags do |docs|
          docs.map do |doc|
            [doc, ds.find { |s| s[:id] == doc.id.to_i }&.[](:tags) || []]
          end.to_h
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
