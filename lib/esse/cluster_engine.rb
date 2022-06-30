# frozen_string_literal: true

module Esse
  class ClusterEngine
    OPENSEARCH_FORK_VERSION = '7.10.2'

    attr_reader :version, :distribution

    def initialize(distribution:, version:)
      @distribution = distribution
      @version = version
    end

    def engine_version
      return @version unless opensearch?

      OPENSEARCH_FORK_VERSION
    end

    def opensearch?
      distribution == 'opensearch'
    end

    def elasticsearch?
      distribution == 'elasticsearch'
    end

    # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.17/removal-of-types.html
    def mapping_single_type?
      engine_version >= '6'
    end
  end
end
