# Getting Started

This guide walks you from installation through creating and searching your first index.

## Installation

Add Esse and one of the official ES/OS clients to your Gemfile:

```ruby
# Choose ONE of:
gem 'elasticsearch' # Elasticsearch 1.x → 8.x
gem 'opensearch-ruby' # OpenSearch 1.x → 2.x

gem 'esse'
```

Then install:

```bash
bundle install
```

Or install directly:

```bash
gem install esse elasticsearch
```

## Generate the config file

Esse ships with a CLI to scaffold files. To generate a config file, run:

```bash
bundle exec esse install
```

This creates `config/esse.rb`. Esse automatically loads any of these paths:

- `Essefile`
- `config/esse.rb`
- `config/initializers/esse.rb`

## Configure a cluster

Edit the generated config to register your cluster(s):

```ruby
# config/esse.rb
require_relative '../environment' unless defined?(Rails)

Esse.configure do |config|
  config.indices_directory = 'app/indices'

  config.cluster(:default) do |cluster|
    cluster.client = Elasticsearch::Client.new(
      url: ENV.fetch('ELASTICSEARCH_URL', 'http://localhost:9200')
    )
  end
end
```

Multiple clusters are supported — see [Configuration](configuration.md).

## Generate an index class

```bash
bundle exec esse generate index UsersIndex
```

This creates `app/indices/users_index.rb` with placeholders for settings, mappings, and a repository.

Fill it in:

```ruby
# app/indices/users_index.rb
class UsersIndex < Esse::Index
  settings do
    {
      index: {
        number_of_shards: 2,
        number_of_replicas: 1
      }
    }
  end

  mappings do
    {
      properties: {
        name:  { type: 'text' },
        email: { type: 'keyword' },
        created_at: { type: 'date' }
      }
    }
  end

  repository :user do
    collection do |**context, &block|
      User.where(context).find_in_batches(batch_size: 1_000) do |batch|
        block.call(batch, context)
      end
    end

    document do |user, **|
      {
        _id:        user.id,
        name:       user.name,
        email:      user.email,
        created_at: user.created_at
      }
    end
  end
end
```

## Create and populate the index

Use the `reset` command to create the index, import data, and set up the alias:

```bash
bundle exec esse index reset UsersIndex
```

This performs a zero-downtime reset:
1. Creates `users_<timestamp>` with your settings/mappings.
2. Imports data from the repository.
3. Points the `users` alias at the new index.
4. Removes the old concrete index.

## Query the index

```ruby
response = UsersIndex.search(
  body: {
    query: {
      match: { name: 'john' }
    }
  }
)

response.total   # total hits
response.results # array of hit hashes
response.each { |hit| puts hit['_source']['name'] }
```

See [Search](search.md) for the full DSL.

## Next steps

- Learn the [Index](index.md) DSL — settings, mappings, aliases, plugins.
- Understand [Repositories](repository.md) — collections, serialization, lazy attributes.
- Explore the [CLI](cli.md) — reset, import, create, update_aliases.
- Hook into [Events](events.md) for observability.
- Use an [ORM extension](extensions.md) like `esse-active_record` or `esse-sequel`.
