# frozen_string_literal: true

class DummyGeosCollection
  include Enumerable
  BATCH_SIZE = 2

  # @param params [Hash] List of parameters
  def initialize(repo:, batch_size: nil, **params)
    @batch_size = batch_size || BATCH_SIZE
    @repo = repo # Some dummy repo that implements #to_a
    @params = params
  end

  def each
    @repo.each_slice(@batch_size) do |rows|
      yield(rows, @params)
    end
  end
end
