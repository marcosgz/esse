# Esse Documentation

Esse is a pure Ruby, framework-agnostic ElasticSearch/OpenSearch client gem that provides an **ETL (Extract, Transform, Load) architecture** for managing search indices.

It is built on top of the official [`elasticsearch-ruby`](https://github.com/elastic/elasticsearch-ruby) and [`opensearch-ruby`](https://github.com/opensearch-project/opensearch-ruby) clients.

## Documentation Index

### Core Concepts

| Guide | Description |
|-------|-------------|
| [Getting Started](getting-started.md) | Installation, configuration and your first index |
| [Configuration](configuration.md) | Global config and cluster management |
| [Index](index.md) | Defining indices, settings, mappings, lifecycle |
| [Repository](repository.md) | Data loading through collections and documents |
| [Document](document.md) | Document classes and variants |
| [Collection](collection.md) | Iterating over data sources |
| [Search](search.md) | Query DSL, response wrapping, scrolls |
| [Import](import.md) | Bulk import pipeline, retries, batching |
| [Transport](transport.md) | Low-level ES/OS client wrapper |
| [Events](events.md) | Pub/sub and instrumentation |
| [Plugins](plugins.md) | Plugin system and how to write custom plugins |
| [CLI](cli.md) | `esse` command-line reference |
| [Errors](errors.md) | Exception hierarchy |

### Ecosystem

| Extension | Purpose |
|-----------|---------|
| [esse-active_record](../../esse-active_record/docs/README.md) | ActiveRecord integration |
| [esse-sequel](../../esse-sequel/docs/README.md) | Sequel ORM integration |
| [esse-rails](../../esse-rails/docs/README.md) | Rails instrumentation |
| [esse-async_indexing](../../esse-async_indexing/docs/README.md) | Background indexing (Sidekiq/Faktory) |
| [esse-hooks](../../esse-hooks/docs/README.md) | Hook/callback state management |
| [esse-jbuilder](../../esse-jbuilder/docs/README.md) | Jbuilder-based search templates |
| [esse-kaminari](../../esse-kaminari/docs/README.md) | Kaminari pagination |
| [esse-pagy](../../esse-pagy/docs/README.md) | Pagy pagination |

See [extensions.md](extensions.md) for the complete list.

## Architecture Overview

Esse is structured around three core components that form an ETL pipeline:

```
Collection (yields batches of raw objects)
       ↓
Repository (serializes batches → Documents)
       ↓
Import pipeline (builds bulk requests with retries)
       ↓
Transport (sends bulk to ES/OS)
```

### Core Components

- **Index** (`Esse::Index`) — defines settings, mappings, aliases, and orchestrates operations.
- **Repository** (`Esse::Repository`) — declares `collection` and `document`, one index may have many.
- **Document** (`Esse::Document`) — a single indexable document with `id`, `type`, `routing`, `source`, `meta`.

### Supporting Components

- **Cluster** — ES/OS client connections, index prefix, readonly mode.
- **Transport** — wraps the official client with consistent error handling.
- **Search** — query DSL builder with response wrapping and scroll support.
- **Events** — pub/sub instrumentation for every ES/OS operation.
- **CLI** — Thor-based CLI (`esse install`, `esse generate`, `esse index *`).
- **Plugins** — extension system loaded via `plugin :name`.

## Quick Example

```ruby
# config/esse.rb
Esse.configure do |config|
  config.cluster(:default) do |cluster|
    cluster.client = Elasticsearch::Client.new(url: ENV['ELASTICSEARCH_URL'])
  end
end

# app/indices/users_index.rb
class UsersIndex < Esse::Index
  settings do
    { index: { number_of_shards: 2, number_of_replicas: 1 } }
  end

  mappings do
    { properties: {
        name:  { type: 'text' },
        email: { type: 'keyword' }
      } }
  end

  repository :user do
    collection do |**ctx, &block|
      User.find_in_batches(batch_size: 1000) { |batch| block.call(batch, ctx) }
    end

    document do |user, **|
      { _id: user.id, name: user.name, email: user.email }
    end
  end
end

# Use:
UsersIndex.create_index(alias: true)
UsersIndex.import
UsersIndex.search(q: 'john').results
```

## Version

Current version: **0.4.0**

Requires Ruby **>= 2.7** and one of:
- `elasticsearch` (any version from 1.x to 8.x)
- `opensearch` (any version from 1.x to 2.x)

## License

MIT — see [LICENSE.txt](../LICENSE.txt).
