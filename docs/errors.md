# Errors

Esse wraps Elasticsearch/OpenSearch client exceptions into a consistent hierarchy so your code does not need to branch on the ES vs OS SDK.

## Hierarchy

```
Esse::Error
├── Esse::Transport::ServerError          # base for any HTTP server error
│   ├── BadRequestError                   # 400
│   ├── UnauthorizedError                 # 401
│   ├── ForbiddenError                    # 403
│   ├── NotFoundError                     # 404
│   ├── RequestTimeoutError               # 408
│   ├── ConflictError                     # 409
│   ├── RequestEntityTooLargeError        # 413
│   ├── UnprocessableEntityError          # 422
│   ├── InternalServerError               # 500
│   ├── BadGatewayError                   # 502
│   ├── ServiceUnavailableError           # 503
│   └── GatewayTimeoutError               # 504
│
├── Esse::Transport::ReadonlyClusterError  # raised on writes when cluster.readonly == true
└── Esse::Transport::BulkResponseError     # bulk partial failure
```

## Catching errors

Most common patterns:

```ruby
begin
  UsersIndex.import
rescue Esse::Transport::ReadonlyClusterError
  # cluster is in readonly mode — skip
rescue Esse::Transport::BulkResponseError => e
  e.response # full response hash
  e.items    # failed items only
rescue Esse::Transport::ServerError => e
  # other HTTP-level failure
rescue Esse::Error => e
  # any Esse error
end
```

## `NotFoundError` nuance

`NotFoundError` is raised on document/index `get`, `delete`, etc. Some lifecycle operations silently ignore it (for example deleting an already-missing index), but `UsersIndex.get(id: 1)` will raise when the document is missing.

Opt out of raising with client-level `ignore`:

```ruby
UsersIndex.get(id: 1, ignore: [404])
# returns nil instead of raising
```

## `BulkResponseError`

A bulk request can succeed at the HTTP level while containing per-item failures. Esse inspects the response and raises `BulkResponseError` when any item has an error:

```ruby
begin
  UsersIndex.import
rescue Esse::Transport::BulkResponseError => e
  e.items.each do |item|
    op, data = item.first
    puts "#{op} failed for id=#{data[:_id]}: #{data.dig(:error, :reason)}"
  end
end
```

## `ReadonlyClusterError`

Raised preemptively when:

- `cluster.readonly = true`, **and**
- you call a write operation (`bulk`, `index`, `update`, `delete`, `create_index`, `delete_index`, `reset_index`, etc.).

Readonly clusters still serve reads (`search`, `count`, `get`, `mget`).

## Writing your own rescue

```ruby
def safe_index(record)
  UsersIndex.index(id: record.id, body: record.as_indexed)
rescue Esse::Transport::ReadonlyClusterError
  Rails.logger.warn("Skipping index — cluster is readonly")
rescue Esse::Transport::RequestEntityTooLargeError
  # split and retry — or let Esse's bulk retry handle it
end
```

## Coercing client exceptions

If you write a custom transport plugin or call the ES client directly, wrap calls in:

```ruby
transport.coerce_exception { client.some_call }
```

This converts ES/OS SDK exceptions into the matching `Esse::Transport::*` subclass.
