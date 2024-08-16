# frozen_string_literal: true

require 'thor'
require_relative 'base'

module Esse
  module CLI
    class Index < Base
      desc 'reset *INDEX_CLASSES', 'Performs zero-downtime index resetting.'
      long_desc <<-DESC
        This task is used to rebuild index with zero-downtime. The task will:
        * Creates a new index using the suffix defined on index class or from CLI.
        * Import documents using the Index collection.
        * Update alias to point to the new index.
        * Delete the old index.
      DESC
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      option :import, type: :boolean, default: true, desc: 'Import documents before point alias to the new index'
      option :reindex, type: :boolean, default: false, desc: 'Use _reindex API to import documents from the old index to the new index'
      option :optimize, type: :boolean, default: true, desc: 'Optimize index before import documents by disabling refresh_interval and setting number_of_replicas to 0'
      option :settings, type: :hash, default: nil, desc: 'List of settings to pass to the index class. Example: --settings=refresh_interval:1s,number_of_replicas:0'
      def reset(*index_classes)
        require_relative 'index/reset'
        opts = HashUtils.deep_transform_keys(options.to_h, &:to_sym)
        if opts[:import] && opts[:reindex]
          raise ArgumentError, 'You cannot use --import and --reindex together'
        end
        Reset.new(indices: index_classes, **opts).run
      end

      desc 'create *INDEX_CLASSES', 'Creates indices for the given classes'
      long_desc <<-DESC
        Creates index and applies mapping and settings for the given classes.

        Indices are created with the following naming convention:
        <cluster.index_prefix>_<index_class.index_name>_<index_class.index_suffix>.
      DESC
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      option :alias, type: :boolean, default: false, aliases: '-a', desc: 'Update alias after create index'
      option :settings, type: :hash, default: nil, desc: 'List of settings to pass to the index class. Example: --settings=index.refresh_interval:-1,index.number_of_replicas:0'
      def create(*index_classes)
        require_relative 'index/create'
        opts = HashUtils.deep_transform_keys(options.to_h, &:to_sym)
        Create.new(indices: index_classes, **opts).run
      end

      desc 'delete *INDEX_CLASSES', 'Deletes indices for the given classes'
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      def delete(*index_classes)
        require_relative 'index/delete'
        Delete.new(indices: index_classes, **options.to_h.transform_keys(&:to_sym)).run
      end

      desc 'update_aliases *INDEX_CLASS', 'Replaces all existing aliases by the given suffix/suffixes'
      option :suffix, type: :string, aliases: '-s', repeatable: true, desc: 'Suffix to append to index name'
      def update_aliases(*index_classes)
        require_relative 'index/update_aliases'

        kwargs = options.to_h.transform_keys(&:to_sym)
        kwargs[:suffix] = (kwargs[:suffix] || []).flat_map { |s| s.split(',') }.uniq
        UpdateAliases.new(indices: index_classes, **kwargs).run
      end

      desc 'update_settings *INDEX_CLASS', 'Closes the index for read/write operations, updates the index settings, and open it again'
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      option :type, type: :string, default: nil, aliases: '-t', desc: 'Document Type to update mapping for'
      option :settings, type: :hash, default: nil, desc: 'List of settings to pass to the index class. Example: --settings=index.refresh_interval:-1,index.number_of_replicas:0'
      def update_settings(*index_classes)
        require_relative 'index/update_settings'
        opts = HashUtils.deep_transform_keys(options.to_h, &:to_sym)
        UpdateSettings.new(indices: index_classes, **opts).run
      end

      desc 'update_mapping *INDEX_CLASS', 'Create or update a mapping'
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      option :type, type: :string, default: nil, aliases: '-t', desc: 'Document Type to update mapping for'
      def update_mapping(*index_classes)
        require_relative 'index/update_mapping'
        UpdateMapping.new(indices: index_classes, **options.to_h.transform_keys(&:to_sym)).run
      end

      desc 'close *INDEX_CLASS', 'Close an index (keep the data on disk, but deny operations with the index).'
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      def close(*index_classes)
        require_relative 'index/close'
        Close.new(indices: index_classes, **options.to_h.transform_keys(&:to_sym)).run
      end

      desc 'open *INDEX_CLASS', 'Open a previously closed index.'
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      def open(*index_classes)
        require_relative 'index/open'
        Open.new(indices: index_classes, **options.to_h.transform_keys(&:to_sym)).run
      end

      desc 'import *INDEX_CLASSES', 'Import documents from the given classes'
      option :suffix, type: :string, default: nil, aliases: '-s', desc: 'Suffix to append to index name'
      option :context, type: :hash, default: {}, required: true, desc: 'List of options to pass to the index class'
      option :repo, type: :string, default: nil, alias: '-r', desc: 'Repository to use for import'
      option :preload_lazy_attributes, type: :string, default: nil, desc: 'Command separated list of lazy document attributes to preload using search API before the bulk import. Or pass `true` to preload all lazy attributes'
      option :eager_load_lazy_attributes, type: :string, default: nil, desc: 'Comma separated list of lazy document attributes to include to the bulk index request. Or pass `true` to include all lazy attributes'
      option :update_lazy_attributes, type: :string, default: nil, desc: 'Comma separated list of lazy document attributes to bulk update after the bulk index request Or pass `true` to include all lazy attributes'

      def import(*index_classes)
        require_relative 'index/import'
        opts = HashUtils.deep_transform_keys(options.to_h, &:to_sym)
        %i[preload_lazy_attributes eager_load_lazy_attributes update_lazy_attributes].each do |key|
          if (val = opts.delete(key)) && val != 'false'
            opts[key] = (val == 'true') ? true : val.split(',')
          end
        end
        Import.new(indices: index_classes, **opts).run
      end
    end
  end
end
