# Extensions

Esse is intentionally minimal. Framework and ORM integration, pagination, async indexing, and template engines are delivered as separate gems. Each extension is a plugin (see [Plugins](plugins.md)) and has its own `docs/` directory.

## ORM integrations

### [esse-active_record](../../esse-active_record/docs/README.md)
`gem 'esse-active_record'` — ActiveRecord support. Adds `collection Model` DSL, `scope`, `batch_context`, automatic after-commit callbacks, and hook-based disabling.

```ruby
class UsersIndex < Esse::Index
  plugin :active_record

  repository :user do
    collection ::User, batch_size: 500 do
      scope :active, -> { where(active: true) }
    end
    document { |u, **| { _id: u.id, name: u.name } }
  end
end

class User < ApplicationRecord
  include Esse::ActiveRecord::Model
  index_callback 'users_index:user'
end
```

### [esse-sequel](../../esse-sequel/docs/README.md)
`gem 'esse-sequel'` — Sequel ORM support with an identical DSL to `esse-active_record`.

---

## Framework integration

### [esse-rails](../../esse-rails/docs/README.md)
`gem 'esse-rails'` — Rails-specific integration. Subscribes to all `elasticsearch.*` events and surfaces aggregate search latency in controller logs (and Lograge).

```
Completed 200 OK in 125.3ms (Views: 45.2ms | Search: 78.1ms)
```

Also auto-loads the Rails environment when `esse` CLI runs in a Rails project.

---

## Async indexing

### [esse-async_indexing](../../esse-async_indexing/docs/README.md)
`gem 'esse-async_indexing'` — Offload indexing to Sidekiq or Faktory. Adds `async_indexing_job` DSL, CLI commands (`esse index async_import`), and ActiveRecord callbacks that enqueue jobs instead of indexing synchronously.

```ruby
class City < ApplicationRecord
  include Esse::AsyncIndexing::ActiveRecord::Model
  async_index_callback('geos_index:city', service_name: :sidekiq) { id }
end
```

---

## Hook management

### [esse-hooks](../../esse-hooks/docs/README.md)
`gem 'esse-hooks'` — The callback/state layer used by `esse-active_record` and `esse-sequel` to enable/disable indexing globally, per-repository, or per-model. Not used directly by end users most of the time; included here for completeness.

```ruby
Esse::ActiveRecord::Hooks.without_indexing { 10.times { User.create! } }
```

---

## Search query templates

### [esse-jbuilder](../../esse-jbuilder/docs/README.md)
`gem 'esse-jbuilder'` — Build search bodies with Jbuilder templates.

```ruby
UsersIndex.search do |json|
  json.query do
    json.match { json.set! 'name', params[:q] }
  end
end
```

Or from a `.json.jbuilder` file:

```ruby
body = Esse::Jbuilder::ViewTemplate.call('users/search', q: params[:q])
UsersIndex.search(body: body)
```

---

## Pagination

### [esse-kaminari](../../esse-kaminari/docs/README.md)
`gem 'esse-kaminari'` — Kaminari integration. Adds `.page(n).per(x)` chainable on search queries.

```ruby
@search = UsersIndex.search(params[:q]).page(params[:page]).per(10)
# View
<%= paginate @search.paginated_results %>
```

### [esse-pagy](../../esse-pagy/docs/README.md)
`gem 'esse-pagy'` — Pagy integration with controller helpers.

```ruby
@pagy, @response = pagy_esse(UsersIndex.pagy_search(params[:q]), items: 10)
```

---

## Testing

### [esse-rspec](../../esse-rspec/docs/README.md)
`gem 'esse-rspec'` — RSpec matchers and index stubs for testing Esse-backed code without a live Elasticsearch/OpenSearch cluster. Intercepts any `Esse::Transport` method and returns canned responses or realistic `Esse::Transport::*` errors. Auto-included on `require 'esse/rspec'`.

Stub a search and assert on the request body:

```ruby
expect(ProductsIndex).to esse_receive_request(:search)
  .with(body: { query: { match_all: {} }, size: 10 })
  .and_return('hits' => { 'total' => 0, 'hits' => [] })

ProductsIndex.search(query: { match_all: {} }, size: 10).response.total # => 0
```

Simulate an HTTP error — the status code maps to the right `Esse::Transport::*` subclass:

```ruby
expect(ProductsIndex).to esse_receive_request(:search)
  .and_raise_http_status(500, { 'error' => 'Something went wrong' })
# raises Esse::Transport::InternalServerError when called
```

Scaffold a disposable `Esse::Index` scoped to a single example:

```ruby
before do
  stub_esse_index('products') do
    repository :product, const: true do
      document { |record| { id: record[:id], name: record[:name] } }
    end
  end
end
```

---

## Other extensions

These extensions are not part of this workspace but are mentioned in the main README:

- **esse-will_paginate** — WillPaginate pagination support.
- **esse-redis_storage** — Redis-backed storage for long-running state.

Visit the [main project](https://github.com/marcosgz/esse) for the complete list.

---

## Writing your own

Any extension is just a plugin module (see [Plugins](plugins.md)). Package it as a gem if you want to share it. The contract is:

- Define a module under `Esse::Plugins::YourName`.
- Optionally add `apply(index, **opts, &block)`, `configure(index, ...)`.
- Optionally add `IndexClassMethods` and `RepositoryClassMethods` submodules.
- Publish with a dependency on `esse` >= 0.3.0 (or your required minimum).
