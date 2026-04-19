# Collection

A **collection** describes how to enumerate the source records of a repository, yielding **batches** rather than individual records. Batching is crucial for bulk indexing performance.

## Block form

The simplest form is a block declared inside a repository:

```ruby
repository :user do
  collection do |**context, &block|
    User.where(context).find_in_batches(batch_size: 1_000) do |batch|
      block.call(batch, context)
    end
  end
end
```

The block receives keyword `context` (passed through from import calls) and a `block` that you call with `(batch_array, context)`.

## Class form

Inherit from `Esse::Collection` for more structure:

```ruby
class MyCollection < Esse::Collection
  def each
    raw_records.each_slice(@params[:batch_size] || 1_000) do |batch|
      yield(batch, @params)
    end
  end

  # Optional: yield only IDs in batches. Used by async indexing and lazy attribute refresh.
  def each_batch_ids
    raw_records.each_slice(@params[:batch_size] || 1_000) do |batch|
      yield(batch.map(&:id))
    end
  end

  private

  def raw_records
    # ...
  end
end

repository :user do
  collection MyCollection
end
```

When the collection is instantiated, it receives the context hash as `@params`:

```ruby
MyCollection.new(batch_size: 500, active: true)
```

## Contract

| Method | Required | Description |
|--------|----------|-------------|
| `each { |batch, context| }` | ✅ | Yield each batch of raw records |
| `each_batch_ids { |ids| }` | Recommended | Yield batches of IDs for efficient async / partial update operations |
| `count` / `size` | Optional | Total record count |

`Esse::Collection` includes `Enumerable`, so you get `map`, `select`, `first` etc. for free once `each` is defined.

## Why `each_batch_ids` matters

Extensions like [esse-async_indexing](../../esse-async_indexing/docs/README.md) rely on this method to enqueue ID-only jobs that don't hold raw record payloads in memory. If your repository only defines `each`, async indexing won't be able to kick off import jobs from the CLI.

If you use [esse-active_record](../../esse-active_record/docs/README.md) or [esse-sequel](../../esse-sequel/docs/README.md) the plugin provides both methods for you:

```ruby
collection ::User # ActiveRecord — both each and each_batch_ids available
```

## Context passing

Whatever keyword arguments are passed as `context:` during import flow are forwarded to the collection:

```ruby
UsersIndex.import(context: { active: true, region: 'us' })
```

…arrives in the collection as:

```ruby
collection do |**context, &block|
  # context => { active: true, region: 'us' }
  User.where(active: context[:active], region: context[:region])
      .find_in_batches { |b| block.call(b, context) }
end
```

The `context` is then forwarded to the `document` block unchanged.

## Custom batching metadata

You can yield additional metadata alongside the batch for the `document` block to consume:

```ruby
collection do |**ctx, &block|
  Order.find_in_batches do |orders|
    # Bulk-fetch related data once per batch
    customers = Customer.where(id: orders.map(&:customer_id)).index_by(&:id)
    block.call(orders, ctx.merge(customers: customers))
  end
end

document do |order, customers: {}, **|
  customer = customers[order.customer_id]
  { _id: order.id, customer_name: customer&.name }
end
```

This "batch context" pattern is the recommended way to avoid N+1 lookups inside serialization.

## ORM integrations

The ORM extensions turn common patterns into DSL:

- [esse-active_record](../../esse-active_record/docs/README.md) adds `collection Model` with `scope` / `batch_context` / `connect_with`.
- [esse-sequel](../../esse-sequel/docs/README.md) provides an identical DSL for Sequel.

```ruby
collection ::User, batch_size: 500 do
  scope :active, -> { where(active: true) }
  batch_context :orders do |users, **|
    Order.where(user_id: users.map(&:id)).group_by(&:user_id)
  end
end
```
