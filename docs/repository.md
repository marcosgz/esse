# Repository

A **repository** is the bridge between a data source and an index. It declares:

- A `collection` — how to iterate over source records in batches.
- A `document` — how to serialize a record into an indexable document.
- (Optional) `lazy_document_attribute` — attributes that are loaded in bulk after primary data.

Repositories are defined inside an index block:

```ruby
class UsersIndex < Esse::Index
  repository :user do
    collection { |**ctx, &b| ... }
    document   { |record, **ctx| ... }
  end
end
```

An index can have multiple repositories — useful when the same index holds heterogeneous document types (e.g., `users` and `admins`, or `posts` and `pages`).

## Collection

The collection must yield batches of raw records. Its signature is:

```ruby
collection do |**context, &block|
  # yield batches
  block.call(batch_array, context)
end
```

### Block form

```ruby
repository :user do
  collection do |**conditions, &block|
    User.where(conditions).find_in_batches(batch_size: 1_000) do |batch|
      block.call(batch, conditions)
    end
  end
end
```

`context` is passed to you from callers (for example `UsersIndex.import(context: { active: true })`) and you pass it on to the `document` block.

### Class form

```ruby
class UserCollection < Esse::Collection
  def each
    User.find_in_batches(batch_size: @params[:batch_size] || 1_000) do |batch|
      yield(batch, @params)
    end
  end

  # Optional — enables more efficient async indexing / lazy attribute refreshes
  def each_batch_ids
    User.select(:id).find_in_batches do |batch|
      yield(batch.map(&:id))
    end
  end
end

repository :user do
  collection UserCollection
end
```

Collection classes inherit from `Esse::Collection`, which is `Enumerable`.

Implementing `each_batch_ids` is strongly recommended: it lets extensions like [esse-async_indexing](../../esse-async_indexing/docs/README.md) enqueue ID-only jobs efficiently.

See [Collection](collection.md) for details.

## Document

Serialize one raw record into an indexable hash or `Esse::Document`:

```ruby
repository :user do
  document do |user, **context|
    {
      _id:        user.id,
      _routing:   user.tenant_id,
      name:       user.name,
      email:      user.email,
      admin:      context[:is_admin]
    }
  end
end
```

Three forms are supported:

```ruby
# 1. Block (most common)
document do |record, **ctx|
  { _id: record.id, name: record.name }
end

# 2. Document class
class UserDocument < Esse::Document
  def id; object.id; end
  def source; { name: object.name, email: object.email }; end
end

document UserDocument

# 3. Callable with to_h / as_json
document MySerializer
```

The hash may include the following reserved keys:

| Key | Purpose |
|-----|---------|
| `_id` / `id` | Document ID (required for most ops) |
| `_type` | Document type (legacy ES <6, normally unused) |
| `_routing` / `routing` | Routing key for custom sharding |

All other keys become the `_source` of the indexed document.

See [Document](document.md) for all document variants.

## Lazy document attributes

Some attributes are expensive to compute per-record. `lazy_document_attribute` lets you resolve them in bulk **after** the primary documents are built:

```ruby
repository :user do
  collection { |**c, &b| User.find_in_batches { |b2| b.call(b2, c) } }
  document   { |u, **| { _id: u.id, name: u.name } }

  lazy_document_attribute :comment_count do |doc_headers|
    counts = Comment.where(user_id: doc_headers.map(&:id)).group(:user_id).count
    doc_headers.each_with_object({}) do |header, hash|
      hash[header] = counts.fetch(header.id, 0)
    end
  end
end
```

The block receives an array of `Esse::LazyDocumentHeader` and must return a hash keyed by those headers.

### Class-based lazy attributes

```ruby
class UserRoles < Esse::DocumentLazyAttribute
  def call(doc_headers)
    # fetch bulk roles keyed by header
  end
end

lazy_document_attribute :roles, UserRoles
```

### Using lazy attributes

```ruby
# Include them during bulk import
UsersIndex.import(eager_load_lazy_attributes: [:roles])

# Refresh them after import (partial updates)
UsersIndex.import(update_lazy_attributes: [:comment_count])

# Or update them independently later
UsersIndex.repo(:user).update_documents_attribute(
  :comment_count, [1, 2, 3], refresh: true
)
```

## Batch iteration helpers

A repository exposes helpers to iterate the collection without importing:

```ruby
UsersIndex.repo(:user).each_batch(active: true) do |batch, ctx|
  # raw record batch
end

UsersIndex.repo(:user).each_serialized_batch(
  eager_load_lazy_attributes: [:roles]
) do |docs|
  # Array[Esse::Document] — already serialized and enriched
end

UsersIndex.repo(:user).documents(active: true) # Enumerator
```

## Partial updates

```ruby
UsersIndex.repo(:user).documents_for_lazy_attribute(:name, ids)
# => Array[Esse::DocumentForPartialUpdate]

UsersIndex.repo(:user).retrieve_lazy_attribute_values(:name, ids)
# => Hash[LazyDocumentHeader => value]
```

## Accessing the index

Inside a repository class:

```ruby
class UsersIndex::User
  def self.index_owner
    UsersIndex       # the parent index
  end
end
```

The repository constant is the pascal-cased name: `UsersIndex::User`, `UsersIndex::Admin`, etc.

## Putting it together

```ruby
class PostsIndex < Esse::Index
  mappings do
    { properties: { title: { type: 'text' }, comments_count: { type: 'integer' } } }
  end

  repository :post do
    collection do |**c, &b|
      Post.includes(:author).find_in_batches(batch_size: 500) { |batch| b.call(batch, c) }
    end

    document do |post, **|
      {
        _id:     post.id,
        title:   post.title,
        author:  post.author.name
      }
    end

    lazy_document_attribute :comments_count do |headers|
      counts = Comment.where(post_id: headers.map(&:id)).group(:post_id).count
      headers.each_with_object({}) { |h, acc| acc[h] = counts.fetch(h.id, 0) }
    end
  end
end

# Import including comment counts
PostsIndex.import(eager_load_lazy_attributes: [:comments_count])
```
