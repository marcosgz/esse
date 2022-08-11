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
    cluster.settings = {
      index: {
        number_of_shards: 4,
        number_of_replicas: 1,
      },
      analysis: {
        analyzer: {
          esse_index: {
            type: "custom",
            char_filter: ["ampersand"],
            filter: [
              "lowercase",
              "asciifolding",
              "esse_english_stop",
              "esse_index_shingle",
              "esse_stemmer"
            ],
            tokenizer: "standard"
          },
        },
        filter: {
          esse_index_shingle: {
            token_separator: "",
            type: "shingle"
          },
          esse_stemmer: {
            type: "stemmer",
            language: "English"
          },
        },
        char_filter: {
          ampersand: {
            type: "mapping",
            mappings: ["&=> and "]
          }
        }
      }
    }
    cluster.mappings = {
      dynamic_templates: [
        {
          esse_string_template: {
            match: "*",
            match_mapping_type: "string",
            mapping: {
              fields: {
                analyzed: {
                  analyzer: "esse_index",
                  index: true,
                  type: "text"
                }
              },
              ignore_above: 1024,
              type: "keyword"
            }
          }
        }
      ]
    }
    cluster.client = Elasticsearch::Client.new(host: 'http://localhost:9200')
  end
end
```

Note that that if the cluster is configured without any identifier, it will be used as the `:default` cluster.

```ruby
Esse.config.cluster.settings
# => {index: {number_of_shards: 4, number_of_replicas: 1} }

# or
Esse.config.cluster(:default).settings
# => {index: {number_of_shards: 4, number_of_replicas: 1} }
```

You may also configure multiple cluster connections by specifying the identifier like the example below:
```ruby
Esse.configure do |config|
  config.indices_directory = 'app/indices'
  config.cluster(:il) do |cluster|
    cluster.index_prefix = 'illinois'
    cluster.settings = {
      index: {
        number_of_shards: 4,
        number_of_replicas: 1,
      }
    }
    cluster.client = Elasticsearch::Client.new(host: 'https://illinois:9200')
  end
  config.cluster(:fl) do |cluster|
    cluster.index_prefix = 'florida'
    cluster.settings = {
      index: {
        number_of_shards: 2,
        number_of_replicas: 2,
      }
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
    settings:
      index:
        number_of_shards: 4
        number_of_replicas: 1
    client:
      host: "https://illinois:9200"
  fl:
    index_prefix: "florida"
    settings:
      index:
        number_of_shards: 2
        number_of_replicas: 2
    client:
      host: "https://florida:9200"
```

## Indices

### Single type per index

The mapping of elasticsearch 1.x, 2.x and 5.x allow multiple types. The single-type-per-index behaviour was introduction on es 5.x disabled as default. After es 6.x de single type per index is enabled by default but the explicit mapping is still required by using the `_doc` type. Es 7.x and above the `_doc` was totally removed and the mapping type is no longer required. The `esse` framework will automatically detect the version of elasticsearch and use the correct mapping type definition. But you can enforce the mapping type by using the `mapping_single_type` option in the `index`(Just make sure the server support it and it's configured accordingly). See [this article](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/removal-of-types.html) for more details.

```ruby
class MyIndex < Esse::Index
  self.mapping_single_type = true # This only control the mapping format. Add the setting `index.mapping.single_type: true` to the index settings in elasticsearch as well if needed.
end
```

## CLI

The `esse` command line tool is available to manage indices and tasks. It's configured to load the configuration from the `Essefile`, `config/esse.rb` or `config/initializers/esse.rb` files(in that order).

```bash
Commands:
  esse --version, -v                # Show package version
  esse generate SUBCOMMAND ...ARGS  # Run generators
  esse help [COMMAND]               # Describe available commands or one specific command
  esse index SUBCOMMAND ...ARGS     # Manage indices
  esse install                      # Generate boilerplate configuration files

Options:
  -r, [--require=REQUIRE]        # Require config file where the application is defined
  -s, [--silent], [--no-silent]  # Silent mode
  -h, [--help], -?, [--usage]    # Show help
```

### Generate Index

Generate an index with the following command:

```bash
$ esse generate index <IndexName> <*doc_type>
```

List of types are optional. If not specified, the index will be created with definition on Index level with the `"default"` as type. Example:

```bash
$ bundle exec esse generate index GeosIndex                                                                                                                                        [ruby-2.6.9p207]
      create  app/indices/geos_index.rb
```

or with multiple datasources as document types:

```bash
$ bundle exec esse generate index GeosIndex state city
      create  app/indices/geos_index.rb
```

As default, the index will be create d with the collection, serializer, settings, mapping directly to the index class. By you can also specify custom arguments to better organize your code by splitting the it into multiple files.

```bash
$ ./exec/esse generate index GeosIndex state city --settings --mappings --serializers --collections                                                                           [ruby-2.6.9p207]
      create  app/indices/geos_index.rb
      create  app/indices/geos_index/templates/settings.json
      create  app/indices/geos_index/templates/mappings.json
      create  app/indices/geos_index/serializers/state_serializer.rb
      create  app/indices/geos_index/collections/state_collection.rb
      create  app/indices/geos_index/serializers/city_serializer.rb
      create  app/indices/geos_index/collections/city_collection.rb
```

### Index Commands

There are several commands to manage indices. The following commands are available:

```bash
$ bundle exec esse index                                                                                                                                                           [ruby-2.6.9p207]
Commands:
  esse index close *INDEX_CLASS                         # Close an index (keep the data on disk, but deny operations with the index).
  esse index create *INDEX_CLASSES                      # Creates indices for the given classes
  esse index delete *INDEX_CLASSES                      # Deletes indices for the given classes
  esse index help [COMMAND]                             # Describe subcommands or one specific subcommand
  esse index import *INDEX_CLASSES --context=key:value  # Import documents from the given classes
  esse index open *INDEX_CLASS                          # Open a previously closed index.
  esse index reset *INDEX_CLASSES                       # Performs zero-downtime index resetting.
  esse index update_aliases *INDEX_CLASS                # Replaces all existing aliases by the given suffix
  esse index update_mapping *INDEX_CLASS                # Create or update a mapping
  esse index update_settings *INDEX_CLASS               # Closes the index for read/write operations, updates the index settings, and open it again
```


## Search

Searching is done through the `search` method on the index class. It returns an instance of `Esse::Search::Query` that can be used to build the query and retrieve the results.

```ruby
# Searching using Lucene query syntax
> query = GeosIndex.search('*', size: 10, offset: 0)
=> #<Esse::Search::Query:0x0 @definition={:size=>10, :offset=>0, :q=>"*", :index=>"esse_console_geos"}>


# Searching using DSL
> query = GeosIndex.search(body: {query: {match: {name: 'Illinois'}}}, size: 1)
=> #<Esse::Search::Query:0x0 @definition={:body=>{:query=>{:match=>{:name=>"Illinois"}}}, :size=>1, :index=>"esse_console_geos"}>

# Retrieve response hits
> query.results
=> [{"_index"=>"esse_console_geos_v1", "_type"=>"_doc", "_id"=>"IL", "_score"=>2.5433555, "_routing"=>"IL", "_source"=>{"id"=>"IL", "name"=>"Illinois"}}]
> query = GeosIndex.search(body: {query: {match: {"name.analyzed" => 'Illinois'}}}, _source: false)
=> #<Esse::Search::Query:0x0 @definition={:body=>{:query=>{:match=>{"name.analyzed"=>"Illinois"}}}, :_source=>false, :index=>"esse_console_geos"}
> query.results
=> [{"_index"=>"esse_console_geos_v1", "_type"=>"_doc", "_id"=>"IL", "_score"=>2.5433555, "_routing"=>"IL"}
# Retrieve response
> query.response
=> #<Esse::Search::Response:0x0 ...>
```

Search aggregations can be retrieved using the `aggregations` method from query response.

```ruby
> query = GeosIndex.search(body: {query: { match_all: {}}, aggregations: { names: { terms: { field: "name", size: 2 }}}}, size: 2)
=> #<Esse::Search::Query:0x0 @definition={:body=>{:query=>{:match_all=>{}}, :aggregations=>{:names=>{:terms=>{:field=>"name", :size=>2}}}}, :size=>2, :index=>"esse_console_geos"}>
> query.response.aggregations
=> {"names"=>{"doc_count_error_upper_bound"=>0, "sum_other_doc_count"=>14, "buckets"=>[{"key"=>"Alabama", "doc_count"=>1}, {"key"=>"Alaska", "doc_count"=>1}]}}

# or just use the raw response
> query.response.raw_response
=> {"took"=>1,
 "timed_out"=>false,
 "_shards"=>{"total"=>1, "successful"=>1, "skipped"=>0, "failed"=>0},
 "hits"=>
  {"total"=>{"value"=>16, "relation"=>"eq"},
   "max_score"=>1.0,
   "hits"=>
    [{"_index"=>"esse_console_geos_v1", "_type"=>"_doc", "_id"=>"AL", "_score"=>1.0, "_routing"=>"AL", "_source"=>{"id"=>"AL", "name"=>"Alabama"}},
     {"_index"=>"esse_console_geos_v1", "_type"=>"_doc", "_id"=>"AK", "_score"=>1.0, "_routing"=>"AK", "_source"=>{"id"=>"AK", "name"=>"Alaska"}}]},
 "aggregations"=>{"names"=>{"doc_count_error_upper_bound"=>0, "sum_other_doc_count"=>14, "buckets"=>[{"key"=>"Alabama", "doc_count"=>1}, {"key"=>"Alaska", "doc_count"=>1}]}}}
> query.response.total
=> 16
```

Scroll queries can be performed using the `scroll_hits` method on the query.

```ruby
> query.scroll_hits(batch_size: 6, scroll: '1m') { |hits| puts hits.size }
6
6
4
=> nil
```

Searching across multiple indices can be done using the `search` method on the cluster.

Using string indices as arguments:

```ruby
> Esse.config.cluster.search('esse_*', body: {query: {match_all:{}}})
=> #<Esse::Search::Query:0x0 @definition={:body=>{:query=>{:match_all=>{}}}, :index=>"esse_*"}>
> Esse.config.cluster.search('esse_cities_index', 'esse_counties_index', body: {query: {match_all:{}}})
=> #<Esse::Search::Query:0x0 @definition={:body=>{:query=>{:match_all=>{}}}, :index=>"esse_cities_index,esse_counties_index"}>
```

Using index classes as arguments:

```ruby
> Esse.config.cluster.search(CitiesIndex, CountiesIndex, body: {query: {match_all:{}}})
=> #<Esse::Search::Query:0x0 @definition={:body=>{:query=>{:match_all=>{}}}, :index=>"esse_cities_index,esse_counties_index"}>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. The command will dependencies of all `./ci/Gemfile.*`. You can use `./ci/setup.sh` combined different environment variables script to start the elasticsearch or opensearch service using docker in different combination. The `./bin/run` will do it for you.

```bash
./bin/run elasticsearch v7 ./ci/setup.sh # Start elasticsearch 7.x
```

Run console for an interactive prompt that will allow you to experiment.

```bash
./bin/run elasticsearch v7 ./bin/console
```

You can use the `./bin/run` script to run specs for some specific elasticsearch version. Tests are using the `ESSE_URL` environment variable and the run script will automatically set the correct elasticsearch version.

```bash
./bin/run elasticsearch v7 bundle exec --gemfile ci/Gemfile.elasticsearch-7.x rspec # Run rspec tests for elasticsearch 7.x
```

If you don't have elasticsearch running and want to ignore integratino tests, you can use the `STUB_STACK=<distribution>-<version>` environment variable to stup the test suite for a specific elasticsearch version. Note that all examples with `:es_version` meta data will be skipped.

```bash
STUB_STACK=elasticsearch-7.0.3 bundle exec --gemfile ci/Gemfile.elasticsearch-7.x rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcosgz/esse.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
