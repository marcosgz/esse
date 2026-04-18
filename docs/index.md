# Index

`Esse::Index` is the main building block. An index class defines:

- **Settings** — shards, replicas, refresh interval, analyzers.
- **Mappings** — field types and analysis rules.
- **Repositories** — how to load and transform data.
- **Plugins** — optional behavior extensions.

Every index class inherits from `Esse::Index`:

```ruby
class UsersIndex < Esse::Index
  # ...
end
```

## Naming

By convention the class name is underscored and the `Index` suffix is stripped:

```ruby
UsersIndex.index_name  # => "myapp_users" (with cluster prefix)
UsersIndex.uname       # => "users_index"
```

You can override the generated name explicitly:

```ruby
class UsersIndex < Esse::Index
  self.index_name = 'users'
  self.index_prefix = 'app1'  # overrides cluster prefix
end

UsersIndex.index_name              # => "app1_users"
UsersIndex.index_name(suffix: 'v2') # => "app1_users_v2"
```

### Index suffixes

Suffixes are used for zero-downtime reindexing. The common pattern:

```bash
bundle exec esse index reset UsersIndex --suffix 20240401
```

This creates `users_20240401`, imports into it, and swaps the alias `users` → `users_20240401`.

## Settings

```ruby
class UsersIndex < Esse::Index
  settings do
    {
      index: {
        number_of_shards:   2,
        number_of_replicas: 1,
        refresh_interval:   '1s'
      },
      analysis: {
        analyzer: {
          my_analyzer: { type: 'standard' }
        }
      }
    }
  end
end
```

Or inline:

```ruby
settings(number_of_shards: 2, refresh_interval: '1s')
```

Simplified keys (`number_of_shards`, `number_of_replicas`, `refresh_interval`, `mapping`) are auto-nested under `index.*`.

The cluster's global `settings` are deep-merged into each index's settings.

## Mappings

```ruby
class UsersIndex < Esse::Index
  mappings do
    {
      properties: {
        name:    { type: 'text' },
        email:   { type: 'keyword' },
        age:     { type: 'integer' },
        roles:   { type: 'keyword' },
        created: { type: 'date' }
      }
    }
  end
end
```

The cluster's global `mappings` are merged into each index.

## Repositories

A **repository** defines *how* to load data into the index. One index can host many repositories.

```ruby
class UsersIndex < Esse::Index
  repository :user do
    collection do |**context, &block|
      User.where(context).find_in_batches { |b| block.call(b, context) }
    end

    document do |user, **|
      { _id: user.id, name: user.name }
    end
  end

  repository :admin do
    collection { |**ctx, &b| User.admins.find_in_batches { |b2| b.call(b2, ctx) } }
    document { |u, **| { _id: u.id, name: u.name, role: 'admin' } }
  end
end
```

See [Repository](repository.md) for the full DSL.

Access:

```ruby
UsersIndex.repo          # default (when only one defined)
UsersIndex.repo(:admin)  # specific
UsersIndex.repo?(:admin) # => true / false
UsersIndex.repo_hash     # => { 'user' => ..., 'admin' => ... }
```

## Plugins

```ruby
class UsersIndex < Esse::Index
  plugin :active_record
  plugin MyCustomPlugin, option: 'value'
end
```

See [Plugins](plugins.md).

## Lifecycle methods

These are the most common class-level operations. All accept `suffix:` and other ES options.

### Create / delete

```ruby
UsersIndex.create_index(alias: true) # create and point alias at it
UsersIndex.delete_index
UsersIndex.index_exist? # => Boolean
```

`create_index` options:

| Option | Type | Description |
|--------|------|-------------|
| `suffix` | `String` | Concrete index suffix (for zero-downtime) |
| `alias` | `Boolean` | Also create the alias `index_name` → suffix |
| `settings` | `Hash` | Override settings |
| `body` | `Hash` | Pass the full body manually |
| `wait_for_active_shards`, `timeout`, `master_timeout`, `headers` | pass-through | Native ES options |

### Reset (zero-downtime)

```ruby
UsersIndex.reset_index(
  suffix:   Time.now.strftime('%Y%m%d'),
  optimize: true,   # temporarily drops replicas/refresh during import
  import:   true,   # import from collection
  reindex:  false   # use _reindex API instead of collection
)
```

The reset flow:

1. Create new index with suffix.
2. (If `optimize: true`) reduce replicas to 0, disable refresh.
3. Import data (or reindex from previous index).
4. Restore settings.
5. Swap the alias.
6. Delete old concrete index.

### Alias management

```ruby
UsersIndex.update_aliases(suffix: '20240401')
UsersIndex.aliases                     # => alias info
UsersIndex.indices_pointing_to_alias   # => concrete index names
```

### Open / close / refresh

```ruby
UsersIndex.close
UsersIndex.open
UsersIndex.refresh
```

### Update settings / mapping

```ruby
UsersIndex.update_settings(settings: { number_of_replicas: 0 })
UsersIndex.update_mapping
```

## Document-level operations

```ruby
UsersIndex.get(id: 1)
UsersIndex.mget(ids: [1, 2, 3])
UsersIndex.exist?(id: 1)
UsersIndex.count(body: { query: { match_all: {} } })

UsersIndex.index(id: 1, body: { name: 'John' })
UsersIndex.update(id: 1, body: { doc: { name: 'Jane' } })
UsersIndex.delete(id: 1)

UsersIndex.bulk(
  index:  [doc1, doc2],
  create: [doc3],
  update: [doc4],
  delete: [doc5]
)
```

## Import

```ruby
UsersIndex.import                           # import all repositories
UsersIndex.import(:user)                    # specific repository
UsersIndex.import(context: { active: true }) # pass context to the collection
UsersIndex.import(
  suffix: '20240401',
  eager_load_lazy_attributes: [:roles],
  update_lazy_attributes:     [:comment_count]
)
```

See [Import](import.md) for details.

## Search

```ruby
UsersIndex.search(q: 'john')
UsersIndex.search(body: { query: { match: { name: 'john' } } })
```

See [Search](search.md).

## Request customization

```ruby
class UsersIndex < Esse::Index
  request_params :index, :update, pipeline: 'my_pipeline' do |doc|
    { routing: doc.routing_key }
  end
end
```

Valid operations are `:index`, `:create`, `:update`, `:delete`.

## Inheritance

Index classes support inheritance — settings, mappings, plugins, and repositories are inherited. Subclass and override what you need:

```ruby
class BaseIndex < Esse::Index
  settings do
    { index: { number_of_replicas: 1 } }
  end
end

class UsersIndex < BaseIndex
  # inherits settings, can override mappings, repositories, etc.
end
```

## Module breakdown

For reference, `Esse::Index` composes these modules (under `lib/esse/index/`):

| Module | Purpose |
|--------|---------|
| `Base` | Cluster binding and naming |
| `Inheritance` | Class inheritance rules |
| `Plugins` | Plugin loading |
| `Attributes` | Directory paths, template dirs |
| `Type` | Repository definition |
| `Settings` | Settings DSL |
| `Mappings` | Mappings DSL |
| `Indices` | Create/delete/reset operations |
| `Documents` | Single-doc ops (get, mget, index, update, bulk…) |
| `Aliases` | Alias ops |
| `Search` | Search entrypoint |
| `ObjectDocumentMapper` | Bulk serialization |
| `RequestConfigurable` | `request_params` DSL |
| `Descendants` | Index tracking |
