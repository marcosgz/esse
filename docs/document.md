# Document

`Esse::Document` is the in-memory representation of a single indexable record. Repositories produce documents; the import pipeline sends them to Elasticsearch.

In most cases you don't interact with `Esse::Document` directly — returning a Hash from your repository `document` block is enough. But understanding the contract is useful for custom document classes, partial updates, and lazy attributes.

## The contract

Every document has these (optionally overridable) methods:

| Method | Description |
|--------|-------------|
| `id` | String/Integer/nil. Documents with `nil` id are ignored on index/delete. |
| `type` | String or nil. Legacy ES type (modern clusters use `_doc` by default). |
| `routing` | String or nil. Used for custom routing. |
| `source` | Hash. The actual document body. |
| `meta` | Hash. Extra metadata merged into bulk operation headers. |

Instance methods:

| Method | Returns |
|--------|---------|
| `object` | The raw record the document was built from |
| `options` | Frozen hash of construction options |
| `to_h` | `{ _id, _type, _routing, ...meta, ...source }` |
| `to_bulk(operation:, data:)` | Bulk-formatted hash |
| `doc_header` | `{ _id, _type, routing }` |
| `ignore_on_index?` | `true` when `id.nil?` |
| `ignore_on_delete?` | `true` when `id.nil?` |

## Writing a custom Document class

```ruby
class UserDocument < Esse::Document
  def id
    object.id
  end

  def routing
    object.tenant_id
  end

  def source
    {
      name:  object.name,
      email: object.email,
      roles: object.role_names
    }
  end
end

# Use it from a repository
repository :user do
  collection { |**c, &b| User.find_in_batches { |u| b.call(u, c) } }
  document   UserDocument
end
```

## Variants

### HashDocument

Auto-extracts header fields from a hash. Most repository `document` blocks implicitly use `HashDocument`:

```ruby
doc = Esse::HashDocument.new(
  _id:      'abc',
  _routing: 'shard-1',
  name:     'John',
  email:    'john@example.com'
)

doc.id      # => 'abc'
doc.routing # => 'shard-1'
doc.source  # => { name: 'John', email: 'john@example.com' }
```

ID is looked up in this order: `_id`, `id`, `:_id`, `:id`. Reserved keys (`_id`, `_type`, `_routing`, `routing`) are stripped from `source`.

### NullDocument

A no-op document, used to skip indexing from inside a `document` block:

```ruby
document do |record, **|
  next Esse::NullDocument.new if record.deleted?
  { _id: record.id, name: record.name }
end
```

`NullDocument#id` is `nil`, so it's automatically ignored by bulk operations.

### DocumentForPartialUpdate

Used when updating a subset of fields on an already-indexed document. Usually created via:

```ruby
doc = original_doc.document_for_partial_update(comment_count: 42)

doc.source # => { comment_count: 42 }
# id, type, routing delegate to original_doc
```

### LazyDocumentHeader

A lightweight placeholder that carries only the information needed to target a document (id, type, routing) and arbitrary extra options. It's the object you receive in `lazy_document_attribute` blocks:

```ruby
lazy_document_attribute :name do |headers|
  # headers is Array[Esse::LazyDocumentHeader]
  ids = headers.map(&:id)
  data = User.where(id: ids).pluck(:id, :name).to_h
  headers.each_with_object({}) { |h, acc| acc[h] = data[h.id] }
end
```

Coerce any input into a header:

```ruby
Esse::LazyDocumentHeader.coerce(1)                  # from ID
Esse::LazyDocumentHeader.coerce('id-123')           # from string
Esse::LazyDocumentHeader.coerce(_id: 1, _routing: 'x')
Esse::LazyDocumentHeader.coerce_each([1, 2, 3])     # batch
```

## Mutations

You can mutate a document before indexing:

```ruby
doc.mutate(:display_name) { "#{object.first_name} #{object.last_name}" }
doc.mutations       # => { display_name: "John Doe" }
doc.mutated_source  # => source.merge(display_name: "John Doe")
```

Mutations are applied when building bulk payloads.

## Equality

```ruby
doc1 = UserDocument.new(user)
doc2 = UserDocument.new(user)
doc1.eql?(doc2) # => true if all headers and source match

# When comparing to a LazyDocumentHeader:
doc1.eql?(header, match_lazy_doc_header: true)
```

## Bulk format

```ruby
doc.to_bulk(operation: :index)
# => { _id: 1, _type: '_doc', data: { name: 'John' } }

doc.to_bulk(operation: :update, data: { doc: { name: 'Jane' } })
# => { _id: 1, _type: '_doc', data: { doc: { name: 'Jane' } } }
```

## When do you write a custom class?

Prefer returning a Hash from the repository `document` block for simple cases. Reach for a custom `Esse::Document` subclass when:

- You want shared logic across many indices.
- You need access to construction options (`doc.options[:foo]`).
- You want mutations / partial updates to be derived cleanly.
- You're building a reusable serializer layer (e.g., across Active Record models).
