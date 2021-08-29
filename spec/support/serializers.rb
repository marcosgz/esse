class DummyGeosSerializer
  def initialize(entry, _scope)
    @entry = entry
  end

  def to_h
    {
      _id: @entry.uuid,
      pk: @entry.id,
      name: @entry.name,
    }
  end
end
