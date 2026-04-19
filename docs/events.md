# Events

Esse ships with a built-in pub/sub instrumentation layer. Every operation against Elasticsearch/OpenSearch emits a named event with a payload. Subscribe to events to instrument, log, or react.

## Subscribing

Two forms are supported:

### Block subscription

```ruby
Esse::Events.subscribe('elasticsearch.bulk') do |event|
  puts "Bulk request: #{event.payload[:runtime]}s"
end
```

### Listener subscription

An object with `on_event_name` methods (dots replaced with underscores) gets auto-subscribed to the matching events:

```ruby
class LoggerListener
  def on_elasticsearch_bulk(event)
    puts "bulk: #{event.payload[:body_size]}b"
  end

  def on_elasticsearch_search(event)
    puts "search: #{event.payload[:runtime]}s"
  end
end

listener = LoggerListener.new
Esse::Events.subscribe(listener)
Esse::Events.subscribed?(listener) # => true
Esse::Events.unsubscribe(listener)
```

## Available events

All events live under the `elasticsearch.*` namespace.

### Documents

| Event | When |
|-------|------|
| `elasticsearch.index` | Single-document index |
| `elasticsearch.update` | Single-document update |
| `elasticsearch.delete` | Single-document delete |
| `elasticsearch.get` | Single-document fetch |
| `elasticsearch.mget` | Multi-get |
| `elasticsearch.exist` | Exists check |
| `elasticsearch.count` | Count query |
| `elasticsearch.bulk` | `_bulk` API call |

### Indices

| Event | When |
|-------|------|
| `elasticsearch.create_index` | `indices.create` |
| `elasticsearch.delete_index` | `indices.delete` |
| `elasticsearch.index_exist` | `indices.exists` |
| `elasticsearch.close` | `indices.close` |
| `elasticsearch.open` | `indices.open` |
| `elasticsearch.refresh` | `indices.refresh` |
| `elasticsearch.update_settings` | `indices.put_settings` |
| `elasticsearch.update_mapping` | `indices.put_mapping` |
| `elasticsearch.update_aliases` | `indices.update_aliases` |

### Search

| Event | When |
|-------|------|
| `elasticsearch.search` | `_search` API |
| `elasticsearch.execute_search_query` | Internal search execution |
| `elasticsearch.reindex` | `_reindex` API |
| `elasticsearch.update_by_query` | `_update_by_query` |
| `elasticsearch.delete_by_query` | `_delete_by_query` |

### Tasks

| Event | When |
|-------|------|
| `elasticsearch.tasks` | List tasks |
| `elasticsearch.task` | Single-task query |
| `elasticsearch.cancel_task` | Cancel task |

## Event payload

Every event is an object with a `payload` hash. Common keys:

| Key | Description |
|-----|-------------|
| `:request` | Request parameters sent to ES/OS |
| `:response` | Response hash |
| `:runtime` | Duration in seconds |
| `:error` | Exception if the call failed |
| `:__started_at__` | Internal start time (Time instance) |

Operation-specific payloads may include `:body_size`, `:document_count`, `:index`, `:type`, etc.

## Publishing

Esse itself publishes events via `Esse::Events.instrument`:

```ruby
Esse::Events.instrument('elasticsearch.bulk') do |payload|
  payload[:body_size] = body.bytesize
  response = client.bulk(body: body)
  payload[:response] = response
  response
end
```

`instrument` records runtime automatically and ensures the event fires even if the block raises.

You can publish custom events too:

```ruby
Esse::Events.publish('myapp.reindex_batch', batch_id: 42, count: 1_000)
```

## Patterns

### Log every ES call

```ruby
Esse::Events.event_names.grep(/^elasticsearch/).each do |event_name|
  Esse::Events.subscribe(event_name) do |event|
    Rails.logger.debug "#{event_name}: #{event.payload[:runtime]}s"
  end
end
```

### Track search latency in Rails

The [esse-rails](../../esse-rails/docs/README.md) gem already subscribes to every `elasticsearch.*` event and surfaces the accumulated runtime in your controller logs:

```
Completed 200 OK in 125.3ms (Views: 45.2ms | Search: 78.1ms)
```

### Fail-fast on bulk errors

```ruby
Esse::Events.subscribe('elasticsearch.bulk') do |event|
  next unless event.payload[:response]

  errors = event.payload[:response].dig(:items) || []
  failed = errors.select { |i| i.values.first[:error] }
  Sentry.capture_message("Bulk had failed items", extra: { failed: failed }) if failed.any?
end
```

## Subscription lifecycle

Subscriptions are stored in-memory for the current process. In a forking server (Puma, Sidekiq), re-subscribe in each worker fork to avoid missing events.

```ruby
Esse::Events.subscribers        # all subscribers
Esse::Events.unsubscribe(subscriber)
Esse::Events.subscribed?(subscriber)
```
