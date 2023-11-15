# frozen_string_literal: true

module Esse
  module Search
    class Query
      module DSL
        def limit(value)
          return self if value.to_i <= 0

          mutate do |defn|
            defn.delete(:size)
            if (body = defn[:body]).is_a?(Hash)
              body[body.key?('size') ? 'size' : :size] = value.to_i
            else
              defn.update(size: value.to_i)
            end
          end
        end

        def offset(value)
          return self if value.to_i < 0

          mutate do |defn|
            defn.delete(:from)
            if (body = defn[:body]).is_a?(Hash)
              body[body.key?('from') ? 'from' : :from] = value.to_i
            else
              defn.update(from: value.to_i)
            end
          end
        end

        def limit_value
          raw_limit_value || 10
        end

        def offset_value
          raw_offset_value || 0
        end

        private

        def mutate
          relation = clone
          if block_given? && (new_query = yield(relation.definition)).is_a?(Hash)
            relation.instance_variable_set(:@definition, new_query)
          end
          relation
        end

        def clone
          self.class.new(transport, **HashUtils.deep_dup(definition))
        end

        def raw_limit_value
          definition.dig(:body, :size) || definition.dig(:body, 'size') || definition.dig(:size) || definition.dig('size')
        end

        def raw_offset_value
          definition.dig(:body, :from) || definition.dig(:body, 'from') || definition.dig(:from) || definition.dig('from')
        end
      end
    end
  end
end
