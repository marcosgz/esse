# Search

Esse provides a thin DSL around Elasticsearch/OpenSearch search APIs, plus a wrapper for responses. You can pass raw query DSL hashes or combine indices and suffixes.

## Running a search

### From an index class

```ruby
query = UsersIndex.search(
  body: {
    query: { match: { name: 'john' } }
  },
  size: 20,
  from: 0
)

query.response          # execute and get Esse::Search::Response
query.response.hits     # array of hit hashes
query.response.total    # total match count
```

### Shorthand

```ruby
UsersIndex.search(q: 'john')              # query string
UsersIndex.search('name:john AND age:30') # Lucene query string
```

### Across multiple indices

```ruby
query = Esse.cluster.search(UsersIndex, EventsIndex, body: { query: { match_all: {} } })
```

## Esse::Search::Query

`UsersIndex.search(...)` returns an `Esse::Search::Query`. It's lazy — no HTTP request is made until you call `.response` or iterate.

Chainable helpers:

```ruby
query.limit(50)         # set size
query.offset(100)       # set from
query.limit_value       # => 50
query.offset_value      # => 100
query.definition        # full query hash sent to ES
query.reset!            # clear cached response
```

Execute:

```ruby
query.response          # Esse::Search::Response
query.results           # alias for response.hits
```

### Pagination

Esse ships without a built-in pagination wrapper. Use:

- [esse-kaminari](../../esse-kaminari/docs/README.md) for Kaminari-style `.page(n).per(x)`.
- [esse-pagy](../../esse-pagy/docs/README.md) for Pagy-style controller helpers.

Or use `.limit(size)` / `.offset(from)` directly.

## Esse::Search::Response

A thin wrapper around the raw ES/OS response:

```ruby
response = query.response

response.raw_response      # raw Hash (the JSON body)
response.query_definition  # what was sent
response.hits              # Array of hit hashes (each has _id, _source, etc.)
response.total             # Integer total matches
response.shards            # shard info
response.aggregations      # aggregations hash (if any)
response.suggestions       # suggestions hash (if any)

response.size              # hits.length
response.empty?
response.each { |hit| ... } # Enumerable
```

## Scrolling

For iterating through very large result sets, use `scroll_hits`:

```ruby
UsersIndex
  .search(body: { query: { match_all: {} } })
  .scroll_hits(batch_size: 1_000, scroll: '1m') do |batch|
    batch.each { |hit| process(hit['_source']) }
  end
```

The scroll context is automatically cleared when the iteration finishes.

## search_after pagination

For live-updated deep pagination (preferred over `from` offsets beyond 10k):

```ruby
UsersIndex
  .search(
    body: {
      query: { match_all: {} },
      sort:  [{ id: 'asc' }]
    }
  )
  .search_after_hits(batch_size: 1_000) do |batch|
    batch.each { |hit| ... }
  end
```

`search_after` requires a sort in the body.

## Suffix targeting

Direct a search at a specific concrete index (not the alias):

```ruby
UsersIndex.search(suffix: '20240401', body: { query: { match_all: {} } })
```

## Example: a search service

```ruby
class UserSearch
  def initialize(query: nil, limit: 20, page: 1)
    @query  = query
    @limit  = limit
    @page   = page
  end

  def call
    UsersIndex.search(
      body: body,
      size: @limit,
      from: (@page - 1) * @limit
    )
  end

  private

  def body
    {
      query: @query ? { multi_match: { query: @query, fields: %w[name email] } }
                    : { match_all: {} },
      sort:  [{ created_at: 'desc' }]
    }
  end
end

search = UserSearch.new(query: 'john', page: 2).call
search.response.total
search.response.each { |hit| puts hit.dig('_source', 'name') }
```

## Integration with Jbuilder

For complex query bodies, [esse-jbuilder](../../esse-jbuilder/docs/README.md) lets you build the body from a Jbuilder template:

```ruby
UsersIndex.search do |json|
  json.query do
    json.bool do
      json.must do
        json.child! { json.match { json.set! 'name', params[:q] } }
      end
    end
  end
end
```

## Counting

```ruby
UsersIndex.count(body: { query: { match: { active: true } } })
# => Integer
```

## Hit format

Each hit is the raw ES response hash:

```ruby
{
  '_index'  => 'myapp_users_20240401',
  '_id'     => '42',
  '_score'  => 1.2,
  '_source' => { 'name' => 'John', 'email' => 'john@example.com' }
}
```

Use `.dig('_source', 'name')` to access source fields, or wrap the response in your own result object.
