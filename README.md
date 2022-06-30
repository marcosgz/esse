# esse

**This project is under development and may suffer constant structural changes. I don't recommend using it right now**

Simple and efficient way to organize queries/mapping/indices/tasks based on the official elasticsearch-ruby.

## Why to use it?
Some facts to use this library:

### Don't spend time learning our DLS
You don't need to spend time learning our DSL or gem usage to start using it. All you need know is the elasticsearch syntax. You are free to build your queries/mappings/settings using JSON/RubyHash flexibility. And keeping simple any elasticsearch upgrade and its syntax changes.

### Multiple ElasticSearch Versions
You can use multiple elasticsearch servers with different versions in an elegant way. Take a look at [LINK TO TOPIC](#anchors-id-here) for more details.

### It's pure Ruby
Yeah!! Nor [activesupport](http://github.com/rails/rails/tree/master/activesupport) dependency and all its monkey patchings. But if you are using rails, suggest install `esse-rails` extension that makes things even easier. Use the [Get started with esse-rails](#anchors-id-here) for more details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'esse'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install esse

## Usage

### Configuration

Example of gem configuration using the `configure` method:
```ruby
Esse.configure do |config|
  config.indices_directory = 'app/indices'
  config.cluster do |cluster|
    cluster.index_prefix = 'illinois'
    cluster.index_settings = {
      number_of_shards: 4,
      number_of_replicas: 1,
    }
    cluster.client = Elasticsearch::Client.new(host: 'http://localhost:9200')
  end
end
```

Note that that if the cluster is configured without any identifier, it will be used as the `:default` cluster.

```ruby
Esse.config.cluster.index_settings
# => {number_of_shards: 4, number_of_replicas: 1}

# or
Esse.config.cluster(:default).index_settings
# => {number_of_shards: 4, number_of_replicas: 1}
```

You may also configure multiple cluster connections by specifying the identifier like the example below:
```ruby
Esse.configure do |config|
  config.indices_directory = 'app/indices'
  config.cluster(:il) do |cluster|
    cluster.index_prefix = 'illinois'
    cluster.index_settings = {
      number_of_shards: 4,
      number_of_replicas: 1,
    }
    cluster.client = Elasticsearch::Client.new(host: 'https://illinois:9200')
  end
  config.cluster(:fl) do |cluster|
    cluster.index_prefix = 'florida'
    cluster.index_settings = {
      number_of_shards: 2,
      number_of_replicas: 2,
    }
    cluster.client = Elasticsearch::Client.new(host: 'https://florida:9200')
  end
end
```

And on the index you can use the `:il` or `:fl` identifier to specify which cluster you want to use.

```ruby
class Illinois::AccountsIndex < Esse::Index(:il)
  ...
end
class Florida::AccountsIndex < Esse::Index(:fl)
  ...
end
```

You can also configure it through the YAML file.
```ruby
Esse.config.load('./config/esse.yml')

# or
Esse.configure do |config|
  config.load('./config/esse.yml')
  config.indices_directory = 'override/indices/directory/from/yml'
end
```

And the `config/esse.yml` file should look like:

```yaml
indices_directory: "app/indices"
clusters:
  il:
    index_prefix: "illinois"
    index_settings:
      number_of_shards: 4
      number_of_replicas: 1
    client:
      host: "https://illinois:9200"
  fl:
    index_prefix: "florida"
    index_settings:
      number_of_shards: 2
      number_of_replicas: 2
    client:
      host: "https://florida:9200"
```

## Indices


## Single type per index

The mapping of elasticsearch 1.x, 2.x and 5.x allow multiple types. The single-type-per-index behaviour was introduction on es 5.x disabled as default. After es 6.x de single type per index is enabled by default but the explicit mapping is still required by using the `_doc` type. Es 7.x and above the `_doc` was totally removed and the mapping type is no longer required. The `esse` framework will automatically detect the version of elasticsearch and use the correct mapping type definition. But you can enforce the mapping type by using the `mapping_single_type` option in the `index`(Just make sure the server support it and it's configured accordingly). See [this article](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/removal-of-types.html) for more details.

```ruby
class MyIndex < Esse::Index
  self.mapping_single_type = true # This only control the mapping format. Add the setting `index.mapping.single_type: true` to the index settings in elasticsearch as well if needed.
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. The command will dependencies of all `./ci/Gemfile.*`. You can use `./ci/setup.sh` combined different environment variables script to start the elasticsearch or opensearch service using docker in different combination. The `./bin/run` will do it for you.

```bash
./bin/run elasticsearch v7 ./ci/setup.sh # Start elasticsearch 7.x
./bin/run elasticsearch v7 bundle exec --gemfile ci/Gemfile.elasticsearch-7.x rspec # Run rspec tests for elasticsearch 7.x
```

You can also run console for an interactive prompt that will allow you to experiment.

```bash
./bin/run elasticsearch v7 ./bin/console
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcosgz/esse.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
