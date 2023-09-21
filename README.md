![esse-red](https://user-images.githubusercontent.com/18994/186032704-f1c9ce86-a41a-41ae-a224-30f4b382c012.png)


# esse - ElasticSearch and OpenSearch Ruby Client

[![build](https://github.com/marcosgz/esse/actions/workflows/build.yml/badge.svg)](https://github.com/marcosgz/esse/actions/workflows/build.yml)

This gem is a Ruby simple and extremely flexible client for ElasticSearch and OpenSearch based on official clients such as [elasticsearch-ruby](https://github.com/elastic/elasticsearch-ruby) and [opensearch-ruby](https://github.com/opensearch-project/opensearch-ruby). It's a pure Ruby implementation, framework agnostic, and due to its modular design, it's easy to extend and adapt to your needs. Esse extensions are available as separate gems. A few examples:

- [esse-kaminari](https://github.com/marcosgz/esse-kaminari) - Kaminari pagination support
- **WIP** [esse-rails](https://github.com/marcosgz/esse-rails) - Ruby on Rails integration. It also includes the active_record extension below by default with a few extra features.
- [esse-active_record](https://github.com/marcosgz/esse-active_record) - ActiveRecord integration
- **WIP** [esse-sequel](https://github.com/marcosgz/esse-sequel) - Sequel integration

## Components

The main idea of the gem is to be compatible with any type of datasource. It means that you can use it with ActiveRecord, Sequel, HTTP APIs, or any other data source. The gem is divided into three main components:

* **Index**: The index is the main component. It's responsible for defining the index settings, mappings, and other index-level configurations. It also provides a DSL to define the next two components.
* **Repository**: The repository is responsible for loading the data. One index may have more than one repo. Each repo must implement a collection. Collection is an Enumerable that iterate over the data in chunks. It may receive a given context for filtering the data that can be used in the next component.
* **Document**: Each repo's collection must have a respective Document. The document is responsible for defining the document itself. It's a simple Ruby object that can be used to define the document id, routing, doc attributes.

This architecture provides a powerful ETL (Extract, Transform, Load) solution for your elasticsearch/opensearch indices.

![image1](https://github.com/marcosgz/esse/assets/18994/7d77c2a3-f71e-4a92-bc19-68690f8206dc)

And to help you to build and interact with the index, the gem provides a CLI tool called `esse`. You can use it to generate index boilerplate, and to interact with index operations and elasticsearch/opensearch cluster

Bellow is an image that shows the main components and how they interact with each other.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elasticsearch' # or gem 'opensearch' with specific version according to your needs
gem 'esse'
```

And then execute:

```bash
❯ bundle install
```

Or install it yourself as:

```bash
❯ gem install esse
```

## Usage

### Configuration
To get started, you need to create the configuration file with the elasticsearch/opensearch cluster connection information. You can use the CLI tool to generate the configuration file:

```bash
❯ esse install
```

The CLI generates the configuration file in the `config/esse.rb` directory. Make sure you require application dependencies in the configuration file if you need to access them in your index classes.

```ruby
require_relative "../environment" unless defined?(Rails)

Esse.configure do |config|
  conf.cluster(:default) do |cluster|
    cluster.client = Elasticsearch::Client.new
  end
end
```

For more information about the configuration options, check out the [Configuration](https://github.com/marcosgz/esse/wiki/Configuration) page.

### Index

Now you need to create an index class. You can use the CLI tool to generate the boilerplate:

```bash
❯ esse generate index PostsIndex
```

For more information about the index class, check out the [Index](https://github.com/marcosgz/esse/wiki/Index) page.

After editing the index class, you can create the index in the elasticsearch/opensearch cluster and start indexing the data. There are several ways to do that. But the easiest way is to use the `index reset` command from the CLI tool:

```bash
❯ esse index reset PostsIndex
```

Reset will create the index with the defined settings and mappings, and then it will start indexing data using the bulk API, and finally, it will point the alias to the created index name. I recommend checking out the [CLI](https://github.com/marcosgz/esse/wiki/CLI) page for more information about the CLI tool.

## More information

In the [wiki](wiki) you can find more information about the gem and how to use it. If you have any questions, feel free to open an issue or contact me on [twitter](https://twitter.com/marcosgz).

<!-- I also recommend checking out the [example rails app](https://github.com/marcosgz/esse-rails-example) that uses esse-rails -->

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcosgz/esse.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
