# Transport

The **transport layer** wraps the official `elasticsearch-ruby` or `opensearch-ruby` client with consistent error handling, event instrumentation, and a uniform API surface across both.

You rarely interact with `Esse::Transport` directly — index classes delegate to it. But understanding what's happening is useful for debugging and extending Esse.

## Access

```ruby
transport = UsersIndex.cluster.api
# or:
transport = Esse::Transport.new(UsersIndex.cluster)

transport.client   # underlying Elasticsearch::Client or OpenSearch::Client
transport.cluster  # the Esse::Cluster
```

## Available modules

The transport composes the following modules (under `lib/esse/transport/`):

| Module | ES/OS APIs covered |
|--------|--------------------|
| `Documents` | `index`, `create`, `update`, `delete`, `get`, `mget`, `bulk`, `count`, `exist`, `reindex`, `update_by_query`, `delete_by_query` |
| `Indices` | `create_index`, `delete_index`, `exists`, `open`, `close`, `refresh`, `update_settings`, `update_mapping`, `get_settings`, `get_mapping`, `index_exist` |
| `Aliases` | `aliases`, `update_aliases`, `indices_pointing_to_alias` |
| `Search` | `search`, `scroll`, `clear_scroll`, `count` |
| `Cluster` | `health`, `info`, `stats`, `tasks`, `cancel_task` |

Each method:

1. Publishes an `elasticsearch.*` event via `Esse::Events.instrument`.
2. Calls through to the client.
3. Wraps ES/OS exceptions into `Esse::Transport::*` exceptions with a consistent hierarchy.
4. Returns the raw response hash.

## Error handling

`Esse::Transport::ServerError` is the base server error. Specific subclasses map HTTP status codes:

| Exception | Status |
|-----------|--------|
| `BadRequestError` | 400 |
| `UnauthorizedError` | 401 |
| `ForbiddenError` | 403 |
| `NotFoundError` | 404 |
| `RequestTimeoutError` | 408 |
| `ConflictError` | 409 |
| `RequestEntityTooLargeError` | 413 |
| `UnprocessableEntityError` | 422 |
| `InternalServerError` | 500 |
| `BadGatewayError` | 502 |
| `ServiceUnavailableError` | 503 |
| `GatewayTimeoutError` | 504 |

Other special exceptions:

- `Esse::Transport::ReadonlyClusterError` — raised when you attempt a write on a `cluster.readonly = true` cluster.
- `Esse::Transport::BulkResponseError` — raised when the bulk response reports per-document errors. Access `error.response` and `error.items`.

See [Errors](errors.md) for the full hierarchy.

## Readonly clusters

Readonly checks happen before any write:

```ruby
cluster.throw_error_when_readonly!
# => Esse::Transport::ReadonlyClusterError if readonly
```

Reads still work:

```ruby
UsersIndex.search(...)          # OK
UsersIndex.count(...)           # OK
UsersIndex.import               # raises ReadonlyClusterError
```

## Calling directly

```ruby
transport = Esse.cluster.api

transport.create_index(index: 'foo', body: { settings: {}, mappings: {} })
transport.delete_index(index: 'foo', ignore: [404])

transport.bulk(body: [
  { index: { _index: 'foo', _id: 1 } }, { name: 'John' }
])
```

Signatures match the underlying clients — consult the ES/OS Ruby client docs for exact parameters.

## Instrumentation

Every call emits an `elasticsearch.*` event:

```ruby
Esse::Events.subscribe('elasticsearch.bulk') do |event|
  puts "bulk runtime=#{event.payload[:runtime]}"
end
```

Payload shape is operation-specific but typically includes `:request`, `:response`, `:runtime`, and `:error` when raised.

See [Events](events.md) for the full event list.

## Coercing exceptions

If you're writing a custom transport plugin or extending behavior, use:

```ruby
transport.coerce_exception do
  client.some_native_call
end
```

This wraps any ES/OS client exception into the matching `Esse::Transport::*` class, keeping callers insulated from ES/OS SDK differences.

## ES vs OS differences

Esse transparently handles a few quirks via `ClusterEngine`:

- ES 6.x+ mapping single-type rules (`_doc` vs `doc`).
- OpenSearch fork version reporting.
- Per-version parameter availability (e.g., `include_type_name`).

This lets you write one index definition that works across ES 1.x → 8.x and OS 1.x → 2.x without branching.
