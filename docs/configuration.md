# Configuration

Esse is configured via `Esse.configure`. The configuration holds global settings (like `indices_directory`) and one or more **clusters**.

## Basic structure

```ruby
Esse.configure do |config|
  config.indices_directory = 'app/indices'
  config.bulk_wait_interval = 0.1

  config.cluster(:default) do |cluster|
    cluster.client = Elasticsearch::Client.new(url: 'http://localhost:9200')
  end
end
```

## Global options

| Option | Default | Description |
|--------|---------|-------------|
| `indices_directory` | `'app/indices'` | Where index files live (used by `Esse.eager_load_indices!`) |
| `bulk_wait_interval` | `0.1` | Seconds to wait between bulk pages to avoid back-pressure |

## Clusters

A **cluster** is a named connection to an Elasticsearch/OpenSearch deployment. Every index is attached to a cluster (defaulting to `:default`).

### Defining a cluster

```ruby
config.cluster(:default) do |cluster|
  cluster.client         = Elasticsearch::Client.new(url: 'http://localhost:9200')
  cluster.index_prefix   = 'myapp'
  cluster.readonly       = false
  cluster.wait_for_status = 'yellow'

  cluster.settings = {
    analysis: { analyzer: { default: { type: 'standard' } } }
  }

  cluster.mappings = {
    properties: {
      created_at: { type: 'date' }
    }
  }
end
```

### Cluster attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `client` | ES/OS client instance | Required. An instance of `Elasticsearch::Client` or `OpenSearch::Client`. |
| `index_prefix` | `String` | Prefix applied to all index names (`"myapp"` → `myapp_users`) |
| `settings` | `Hash` | Global settings merged into every index |
| `mappings` | `Hash` | Global mappings merged into every index |
| `wait_for_status` | `'green' \| 'yellow' \| 'red'` | Wait until cluster reaches this status before operations |
| `readonly` | `Boolean` | When `true`, write operations raise `Esse::Transport::ReadonlyClusterError` |

You can also assign attributes in bulk via `cluster.assign(hash)`.

### Multiple clusters

```ruby
Esse.configure do |config|
  config.cluster(:default) do |c|
    c.client = Elasticsearch::Client.new(hosts: %w[es-primary:9200])
  end

  config.cluster(:analytics) do |c|
    c.client = Elasticsearch::Client.new(hosts: %w[es-analytics:9200])
    c.index_prefix = 'analytics'
  end
end

class UsersIndex < Esse::Index
  self.cluster_id = :default # default
end

class EventsIndex < Esse::Index
  self.cluster_id = :analytics
end
```

Set the default cluster for all index subclasses:

```ruby
Esse::Index.cluster_id = :v1
```

### Accessing a cluster

```ruby
Esse.cluster              # => cluster :default
Esse.cluster(:analytics)  # => named cluster
Esse.config.cluster_ids   # => [:default, :analytics]

UsersIndex.cluster        # => cluster attached to the index
UsersIndex.cluster_id     # => :default
```

### Engine detection

Esse auto-detects the running ES/OS distribution and version via `ClusterEngine`:

```ruby
engine = UsersIndex.cluster.engine
engine.elasticsearch?        # => true / false
engine.opensearch?           # => true / false
engine.engine_version        # => "8.12.0"
engine.mapping_single_type?  # => true for ES >= 6
engine.mapping_default_type  # => :_doc | :doc | nil
```

Esse uses this information to stay compatible across ES/OS versions without you having to branch.

## Readonly mode

Readonly mode is a hard safety switch. Any write operation (create, delete, update, bulk, reset) on a readonly cluster raises `Esse::Transport::ReadonlyClusterError`. Reads work normally.

```ruby
config.cluster(:default) do |c|
  c.client   = Elasticsearch::Client.new
  c.readonly = Rails.env.production? && ENV['READ_ONLY_MODE'] == 'true'
end
```

This is useful during migrations or to protect replicas.

## Waiting for status

```ruby
config.cluster(:default) do |c|
  c.wait_for_status = 'yellow'
end

Esse.cluster.wait_for_status! # called before risky ops like reset
```

Valid values: `'green'`, `'yellow'`, `'red'`. Set to `nil` to disable.

## Loading from YAML

`Esse::Config#load` accepts a file path, Pathname, or Hash:

```ruby
Esse.config.load('config/esse.yml')
```

The YAML is parsed and applied to `Esse.config`. Keys at the root become cluster definitions, and top-level keys map to config attributes.

## Thread safety

Mutable state is guarded by `Esse.synchronize`. You can set `Esse.instance_variable_set(:@single_threaded, true)` to skip locking in single-threaded tests.

## Logging

```ruby
Esse.logger = Logger.new($stdout)
Esse.logger = nil # silent (File::NULL)
```

See [Events](events.md) for richer observability.
