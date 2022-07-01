module Hooks
  # Allows to set the Elasticsearch version to be used in the tests using real
  module ServiceType
    def self.included(base)
      base.around(:example) do |example|
        case example.metadata[:service_type]
        when :elasticsearch
          example.metadata[:skip] = 'Ignoring ElasticSearch tests' unless defined?(Elasticsearch::VERSION)
        when :opensearch
          example.metadata[:skip] = 'Ignoring OpenSearch tests' unless defined?(OpenSearch::VERSION)
        end

        example.metadata[:skip] ? example.skip : example.run
      end
    end
  end
end
