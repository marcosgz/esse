# frozen_string_literal: true

require 'thor'
require_relative 'base'

module Esse
  module CLI
    class Index < Base
      desc 'create *INDEX_CLASSES', 'Creates indices for the given classes'
      long_desc <<-DESC
        Creates index and applies mapping and settings for the given classes.

        Indices are created with the following naming convention:
        <cluster.index_prefix>_<index_class.index_name>_<index_class.index_version>.
      DESC
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      option :alias, type: :boolean, default: false, aliases: '-a', desc: 'Update alias after create index'
      def create(*index_classes)
        require_relative 'index/create'
        Create.new(indices: index_classes, **options.transform_keys(&:to_sym)).run
      end

      desc 'delete *INDEX_CLASSES', 'Deletes indices for the given classes'
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      def delete(*index_classes)
        require_relative 'index/delete'
        Delete.new(indices: index_classes, **options.transform_keys(&:to_sym)).run
      end
    end
  end
end
