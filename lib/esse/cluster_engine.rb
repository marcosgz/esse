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

    # @see https://www.elastic.co/guide/en/elasticsearch/reference/6.3/mapping.html
    # @see https://www.elastic.co/guide/en/elasticsearch/reference/6.4/mapping.html
    # @see https://www.elastic.co/guide/en/elasticsearch/reference/7.1/mapping.html
    def mapping_default_type
      return unless engine_version.to_i == 6

      engine_version >= '6.4' ? :_doc : :doc
    end
  end
end
