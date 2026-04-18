# CLI

Esse ships with a Thor-based CLI called `esse`. It handles scaffolding, index lifecycle, and bulk operations.

## Running

```bash
bundle exec esse <command> [options]
```

Or as a standalone executable:

```bash
gem install esse
esse <command>
```

## Global options

| Flag | Description |
|------|-------------|
| `--require FILE`, `-r FILE` | Require a file before executing (useful for a custom config) |
| `--silent`, `-s` | Suppress event output |
| `--version`, `-v` | Print version |
| `--help` | Print help |

## Configuration paths

The CLI auto-loads the first existing file from:

1. `Essefile`
2. `config/esse.rb`
3. `config/initializers/esse.rb`

In a Rails app, add `require 'esse/rails'` (via the [esse-rails](../../esse-rails/docs/README.md) gem) and the Rails environment is loaded automatically.

## Commands

### `esse install`

Generate a configuration file template:

```bash
bundle exec esse install
bundle exec esse install --path config/my_esse.rb
```

Options:

| Flag | Default | Description |
|------|---------|-------------|
| `--path` / `-p` | `config/esse.rb` | Target path |

### `esse generate index <CLASS_NAME>`

Scaffold a new index class:

```bash
bundle exec esse generate index UsersIndex
```

Creates `app/indices/users_index.rb` (or wherever `Esse.config.indices_directory` points) with a template.

---

### `esse index reset <INDEX_CLASS>`

Zero-downtime index reset — create a new concrete index, import data, swap the alias, and remove the old one.

```bash
bundle exec esse index reset UsersIndex --suffix 20240401 --optimize
```

| Option | Default | Description |
|--------|---------|-------------|
| `--suffix` | timestamp | Concrete index suffix |
| `--import` | `true` | Import from collection |
| `--reindex` | `false` | Use ES `_reindex` API instead of importing |
| `--optimize` | `true` | Temporarily drop replicas/refresh for faster bulk |
| `--settings` | — | JSON/hash to override index settings |
| `--preload_lazy_attributes` | — | Preload lazy attributes via search before import |
| `--eager_load_lazy_attributes` | — | Resolve lazy attributes during bulk |
| `--update_lazy_attributes` | — | Partial-update lazy attributes after bulk |

### `esse index create <INDEX_CLASS>`

Create an index without importing:

```bash
bundle exec esse index create UsersIndex --alias
```

| Option | Default | Description |
|--------|---------|-------------|
| `--suffix` | — | Concrete suffix |
| `--alias` | `false` | Also create the alias pointing at the index |
| `--settings` | — | Override settings |

### `esse index delete <INDEX_CLASS>`

```bash
bundle exec esse index delete UsersIndex --suffix 20240401
```

### `esse index import <INDEX_CLASS>`

```bash
bundle exec esse index import UsersIndex \
  --repo user \
  --context active:true,region:us \
  --suffix 20240401
```

| Option | Description |
|--------|-------------|
| `--repo` | Specific repository (omit to import all) |
| `--suffix` | Target index suffix |
| `--context` | Context hash for collection filtering |
| `--preload_lazy_attributes` | Preload via search |
| `--eager_load_lazy_attributes` | Resolve during bulk |
| `--update_lazy_attributes` | Refresh as partial updates |

### `esse index open <INDEX_CLASS>` / `esse index close <INDEX_CLASS>`

Open or close the index:

```bash
bundle exec esse index close UsersIndex
bundle exec esse index open UsersIndex
```

### `esse index update_aliases <INDEX_CLASS>`

Point the alias at one or more concrete indices:

```bash
bundle exec esse index update_aliases UsersIndex --suffix 20240401
bundle exec esse index update_aliases UsersIndex --suffix v1,v2
```

### `esse index update_settings <INDEX_CLASS>`

```bash
bundle exec esse index update_settings UsersIndex --settings number_of_replicas:2
```

### `esse index update_mapping <INDEX_CLASS>`

```bash
bundle exec esse index update_mapping UsersIndex
bundle exec esse index update_mapping UsersIndex --suffix 20240401
```

### `esse index update_lazy_attributes <INDEX_CLASS> <attr> [attr ...]`

Refresh specific lazy attributes without a full reindex:

```bash
bundle exec esse index update_lazy_attributes UsersIndex comment_count follower_count \
  --repo user \
  --context active:true
```

| Option | Description |
|--------|-------------|
| `--repo` | Repository name (required when multiple) |
| `--suffix` | Target suffix |
| `--context` | Collection context |
| `--bulk_options` | Extra ES bulk options |

## Extension commands

Gems like [esse-async_indexing](../../esse-async_indexing/docs/README.md) add more subcommands:

```bash
bundle exec esse index async_import UsersIndex --service sidekiq
bundle exec esse index async_update_lazy_attributes UsersIndex comment_count --service sidekiq
```

Consult each extension's documentation for details.

## Exit codes

- `0` — success
- non-zero — any error

Use `--silent` in CI to reduce noise.

## Example workflows

### First-time bootstrap

```bash
bundle exec esse install
# edit config/esse.rb
bundle exec esse generate index UsersIndex
# edit app/indices/users_index.rb
bundle exec esse index reset UsersIndex
```

### Daily reindex via cron

```bash
bundle exec esse index reset UsersIndex --suffix $(date +%Y%m%d) --optimize
```

### Partial refresh

```bash
bundle exec esse index update_lazy_attributes UsersIndex comment_count
```
