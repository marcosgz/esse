# frozen_string_literal: true

require 'thor'
require_relative 'base'

module Esse
  module CLI
    class Index < Base
      desc 'create *INDEX_CLASSES', 'Performs zero-downtime index resetting.'
      long_desc <<-DESC
        This task is used to rebuild index with zero-downtime. The task will:
        * Creates a new index using the suffix defined on index class or from CLI.
        * Import documents using the Index collection.
        * Update alias to point to the new index.
        * Delete the old index.
      DESC
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      def reset(*index_classes)
        require_relative 'index/reset'
        Reset.new(indices: index_classes, **options.transform_keys(&:to_sym)).run
      end

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

      desc 'update_settings *INDEX_CLASS', 'Closes the index for read/write operations, updates the index settings, and open it again'
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      option :type, type: :string, default: nil, aliases: '-t', desc: 'Document Type to update mapping for'
      def update_settings(*index_classes)
        require_relative 'index/update_settings'
        UpdateSettings.new(indices: index_classes, **options.transform_keys(&:to_sym)).run
      end

      desc 'update_mapping *INDEX_CLASS', 'Create or update a mapping'
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      option :type, type: :string, default: nil, aliases: '-t', desc: 'Document Type to update mapping for'
      def update_mapping(*index_classes)
        require_relative 'index/update_mapping'
        UpdateMapping.new(indices: index_classes, **options.transform_keys(&:to_sym)).run
      end

      desc 'close *INDEX_CLASS', 'Close an index (keep the data on disk, but deny operations with the index).'
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      def close(*index_classes)
        require_relative 'index/close'
        Close.new(indices: index_classes, **options.transform_keys(&:to_sym)).run
      end

      desc 'open *INDEX_CLASS', 'Open a previously closed index.'
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      def open(*index_classes)
        require_relative 'index/open'
        Open.new(indices: index_classes, **options.transform_keys(&:to_sym)).run
      end
    end
  end
end
