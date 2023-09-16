![esse-red](https://user-images.githubusercontent.com/18994/186032704-f1c9ce86-a41a-41ae-a224-30f4b382c012.png)


# esse - ElasticSearch and OpenSearch Ruby Client

[![build](https://github.com/marcosgz/esse/actions/workflows/build.yml/badge.svg)](https://github.com/marcosgz/esse/actions/workflows/build.yml)

This gem is a Ruby simple and extremely flexible client for ElasticSearch and OpenSearch based on official clients such as [elasticsearch-ruby](https://github.com/elastic/elasticsearch-ruby) and [opensearch-ruby](https://github.com/opensearch-project/opensearch-ruby). It's a pure Ruby implementation, and due to its modular design, it's easy to extend and adapt to your needs. Esse extensions are available as separate gems. A few examples:

- [esse-kaminari](https://github.com/marcosgz/esse-kaminari) - Kaminari pagination support
- **WIP** [esse-rails](https://github.com/marcosgz/esse-rails) - Ruby on Rails integration. It also includes the active_record extension below by default with a few extra features.
- [esse-active_record](https://github.com/marcosgz/esse-active_record) - ActiveRecord integration
- **WIP** [esse-sequel](https://github.com/marcosgz/esse-sequel) - Sequel integration

# Components

The main idea of the gem is to be compatible with any type of datasource. It means that you can use it with ActiveRecord, Sequel, HTTP APIs, or any other data source. The gem is divided into three main components:

* **Index**: The index is the main component. It's responsible for defining the index settings, mappings, and other index-level configurations. It also provides a DSL to define the next two components.
* **Collection**: The collection is responsible for loading the data. It's an Enumerable object that can be used to iterate over the data in chunks. It can also used to pass some metadata for next component.
* **Document**: The document is responsible for defining the document itself. It's a simple Ruby object that can be used to define the document id, routing, index group, doc attributes.

And to help you to build and interact with the index, the gem provides a CLI tool called `esse`. You can use it to generate index boilerplate, and to interact with index operations and elasticsearch/opensearch cluster.

Bellow is an image that shows the main components and how they interact with each other.
