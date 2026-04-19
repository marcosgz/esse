# Import

`import` is the process of walking a repository's collection, serializing records to documents, and sending them to Elasticsearch/OpenSearch in batches using the `_bulk` API.

## Basic usage

```ruby
UsersIndex.import                      # all repositories
UsersIndex.import(:user)               # specific repository
UsersIndex.import(:user, :admin)       # multiple repositories
```

Or from the CLI:

```bash
bundle exec esse index import UsersIndex
bundle exec esse index import UsersIndex --repo user
```

## Options

```ruby
UsersIndex.import(
  :user,
  suffix:                      '20240401',         # concrete index suffix
  context:                     { active: true },   # passed to collection + document
  eager_load_lazy_attributes:  [:roles],           # include these before bulk
  update_lazy_attributes:      [:comment_count],   # refresh after bulk
  preload_lazy_attributes:     true                # fetch via search before import
)
```

| Option | Description |
|--------|-------------|
| `suffix` | Target concrete index (e.g., for zero-downtime reset). Defaults to the alias. |
| `context` | Hash forwarded to the collection and then to the document block. |
| `eager_load_lazy_attributes` | Resolve these lazy attributes during import and include them in the bulk payload. Use `true` for all. |
| `update_lazy_attributes` | After the initial bulk, send partial updates for these attributes. |
| `preload_lazy_attributes` | If `true`, use the search API to pre-read current lazy attribute values and skip rewrites. |

## Flow overview

```
collection.each { |batch, ctx|
  repository.serialize_batch(batch, ctx)
    → Array[Esse::Document]
  import.bulk(documents)
    → _bulk API call with retry and size handling
}
```

## Bulk API and retries

Bulk requests are built by `Esse::Import::Bulk`. It splits operations by type (`index`, `create`, `update`, `delete`) and:

1. Writes one bulk payload per batch.
2. Detects `413 Request Entity Too Large` → splits and retries in smaller chunks.
3. Detects timeouts → exponential backoff: `(retry**4) + 15 + rand(10) * (retry + 1)` seconds.
4. Gives up after 4 retries (configurable via `max_retries:`).
5. On the last retry, optionally switches to one-doc-per-request mode (`last_retry_in_small_chunks:`).

## Optimizing during import

Esse can temporarily disable replicas and refresh for huge imports, then restore them:

```bash
bundle exec esse index reset UsersIndex --optimize
```

Equivalent to:

```ruby
UsersIndex.reset_index(optimize: true, import: true)
```

When `optimize: true` is set, Esse sets `number_of_replicas: 0` and `refresh_interval: -1` before the bulk walk, then restores the original values after.

## Zero-downtime reset

The common full-reindex workflow is:

```bash
bundle exec esse index reset UsersIndex --suffix 20240401
```

Internally this is:

1. `create_index(suffix: '20240401')` — create `users_20240401`.
2. `import(suffix: '20240401')` — fill it up.
3. `update_aliases(suffix: '20240401')` — point `users` alias at new index.
4. Delete the previous concrete index.

See [Index](index.md#reset-zero-downtime) for details.

## Lazy attributes during import

If your repository declares `lazy_document_attribute`, you can mix and match how to load them:

```ruby
UsersIndex.import(
  eager_load_lazy_attributes: [:roles],      # in the initial bulk
  update_lazy_attributes:     [:comment_count] # as partial updates after bulk
)
```

`eager_load_lazy_attributes: true` resolves all declared lazy attributes during the initial bulk. Use an array to pick specific ones.

## Bulk settings

| Setting | Default | Description |
|---------|---------|-------------|
| `bulk_wait_interval` | `0.1` | Seconds to wait between bulk pages (set via `Esse.config.bulk_wait_interval`) |
| `batch_size` | Collection-dependent | Passed through from your collection implementation |

## Import errors

Bulk operations may succeed overall while having per-item errors. Esse raises `Esse::Transport::BulkResponseError` when the response contains errors:

```ruby
begin
  UsersIndex.import
rescue Esse::Transport::BulkResponseError => e
  e.response # full raw response hash
  e.items    # items that failed, each with their ES error
end
```

See [Errors](errors.md) for the full exception hierarchy.

## Events

Every bulk request emits `elasticsearch.bulk`. Subscribe to audit or instrument imports:

```ruby
Esse::Events.subscribe('elasticsearch.bulk') do |event|
  Rails.logger.info "Bulk: #{event.payload[:body_size]}b in #{event.payload[:runtime]}s"
end
```

See [Events](events.md).

## CLI reference

```bash
bundle exec esse index import UsersIndex \
  --suffix 20240401 \
  --repo user \
  --context active:true \
  --eager_load_lazy_attributes roles \
  --update_lazy_attributes comment_count
```

See [CLI](cli.md) for the full command reference.
