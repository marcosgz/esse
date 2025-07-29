# frozen_string_literal: true

module Esse
  class Index
    module ClassMethods
      def combined_request_params_for?(operation)
        request_params_for?(operation) || cluster.request_params_for?(operation)
      end

      def combined_request_params_for(operation, doc)
        params = request_params_for(operation, doc) || {}
        return params unless cluster.request_params_for?(operation)

        cluster.request_params_for(operation, doc).merge(params)
      end

      def combined_request_body_for?(operation)
        request_body_for?(operation) || cluster.request_body_for?(operation)
      end

      def combined_request_body_for(operation, doc)
        body = request_body_for(operation, doc) || {}
        return body unless cluster.request_body_for?(operation)

        cluster.request_body_for(operation, doc).merge(body)
      end
    end

    extend Esse::RequestConfigurable
    extend ClassMethods
  end
end
