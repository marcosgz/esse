class DummyGeosSerializer
  def initialize(entry, _scope)
    @entry = entry
  end

  def as_json
    {
      _id: @entry.uuid,
      pk: @entry.id,
      name: @entry.name,
    }
  end
end
