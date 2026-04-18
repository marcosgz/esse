# Plugins

Plugins are the primary extension mechanism in Esse. They can:

- Add class methods to indices and repositories.
- Hook into the index load process.
- Wrap or override existing behavior.
- Add custom DSL methods.

Official extensions ([esse-active_record](../../esse-active_record/docs/README.md), [esse-async_indexing](../../esse-async_indexing/docs/README.md), [esse-jbuilder](../../esse-jbuilder/docs/README.md), etc.) are all plugins.

## Using plugins

```ruby
class UsersIndex < Esse::Index
  plugin :active_record
  plugin :async_indexing
  plugin MyCustomPlugin, option: 'value'
end

UsersIndex.plugins # => [Esse::Plugins::ActiveRecord, Esse::Plugins::AsyncIndexing, MyCustomPlugin]
```

You can pass a symbol (which is `require`d from `esse/plugins/<name>`) or a module directly. Options and blocks are forwarded to `apply` / `configure`.

## Writing a plugin

A plugin is a module under `Esse::Plugins::` with any of the following hooks:

```ruby
module Esse
  module Plugins
    module MyPlugin
      # Called once when the plugin is added to the index
      def self.apply(index, **options, &block)
        # install class-level defaults, validate options, etc.
      end

      # Called after apply, for DSL-style configuration
      def self.configure(index, **options, &block)
        index.some_setting = options[:default]
      end

      # Mixed into index classes (available on MyIndex.*)
      module IndexClassMethods
        def custom_index_method
          # ...
        end
      end

      # Mixed into each repository class (available on MyIndex::Repo.*)
      module RepositoryClassMethods
        def custom_repo_method
          # ...
        end
      end
    end
  end
end
```

Load the plugin (either autoload via `plugin :my_plugin` which requires `esse/plugins/my_plugin`, or require it manually), then:

```ruby
class UsersIndex < Esse::Index
  plugin :my_plugin, default: :foo
end

UsersIndex.custom_index_method
UsersIndex.repo(:user).custom_repo_method
```

## Plugin execution order

1. `plugin :name` calls `apply(index, **opts, &block)` on the module.
2. `configure(index, **opts, &block)` runs.
3. `IndexClassMethods` are extended into the index class.
4. `RepositoryClassMethods` are extended into each repository as they're declared.

Plugins declared earlier apply first; later plugins can override earlier behavior.

## Inheriting plugins

Plugins are inherited by subclasses:

```ruby
class AppIndex < Esse::Index
  plugin :active_record
end

class UsersIndex < AppIndex
  # active_record is already applied
end
```

## Example: a simple plugin

```ruby
module Esse::Plugins::DefaultLogger
  def self.apply(index, **)
    Esse.logger.info "Loaded index #{index.name}"
  end

  module IndexClassMethods
    def log_info
      Esse.logger.info "#{name}: #{cluster_id}"
    end
  end
end

class UsersIndex < Esse::Index
  plugin Esse::Plugins::DefaultLogger
end

UsersIndex.log_info
```

## Example: an ORM-style plugin

This is a simplified version of what [esse-active_record](../../esse-active_record/docs/README.md) does:

```ruby
module Esse::Plugins::MyORM
  module RepositoryClassMethods
    def collection(klass, **opts, &block)
      coll_class = Class.new(Esse::Collection) do
        define_method(:each) do
          klass.find_in_batches(batch_size: opts[:batch_size] || 1_000) do |batch|
            yield(batch, @params)
          end
        end
      end
      super(coll_class, **opts, &block)
    end
  end
end
```

## Using existing extensions

See [extensions.md](extensions.md) for the curated list. For each, `plugin :<name>` enables it — the rest is ORM-specific DSL documented in its own `docs/`.
