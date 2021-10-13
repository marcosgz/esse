# frozen_string_literal: true

module Esse
  module CLI
    class Index::BaseOperation
      include Output

      def initialize(indices:, **options)
        @indices = Array(indices)
        @options = options
      end

      # @abstract
      # @void
      def run
        raise NotImplementedError
      end

      private

      def validate_indices_option!
        if @indices.empty?
          raise InvalidOption.new(<<~END)
            You must specify at least one index class.

            Example:
              > esse index create CityIndex
              > esse index create CityIndex, StateIndex
          END
        end
      end

      def indices
        eager_load_indices!
        @indices.map do |class_name|
          const_exist = begin
            Kernel.const_defined?(class_name)
          rescue NameError
            false
          end

          raise InvalidOption.new(<<~END, class_name: class_name) unless const_exist
            Unrecognized index class: %<class_name>p. Are you sure you specified the correct index class?
          END

          klass = Kernel.const_get(class_name)
          unless klass < Esse::Index
            path = Esse.config.indices_directory.join(Hstring.new(class_name).underscore.to_s)
            raise InvalidOption.new(<<~END, class_name: class_name, path: path)
              %<class_name>s must be a subclass of Esse::Index.

              Example:
                # %<path>s.rb
                class %<class_name>s < Esse::Index
                  # the index definition goes here
                end
            END
          end

          klass
        end
      end

      def eager_load_indices!
        return false unless Esse.config.indices_directory.exist?

        Esse.config.indices_directory.each_child do |path|
          require path
        end
        true
      end
    end
  end
end
