# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'deprecations' do
  before do
    stub_index(:posts)
  end

  shared_examples 'backend operation moved to index' do |outdated, replacement|
    describe "Esse::Index.backend.#{outdated} moved to Esse::Index.#{replacement}" do
      specify do
        expect(PostsIndex).to receive(replacement).and_return(:ok)
        Gem::Deprecate.skip_during do
          expect(PostsIndex.backend.send(outdated)).to eq(:ok)
        end
      end
    end

    describe "Esse::Index.elasticsearch.#{outdated} moved to Esse::Index.#{replacement}" do
      specify do
        expect(PostsIndex).to receive(replacement).and_return(:ok)
        Gem::Deprecate.skip_during do
          expect(PostsIndex.elasticsearch.send(outdated)).to eq(:ok)
        end
      end
    end
  end

  include_examples 'backend operation moved to index', :aliases, :aliases
  include_examples 'backend operation moved to index', :indices, :indices_pointing_to_alias
  include_examples 'backend operation moved to index', :update_aliases!, :update_aliases
  include_examples 'backend operation moved to index', :update_aliases, :update_aliases
  include_examples 'backend operation moved to index', :create_index, :create_index
  include_examples 'backend operation moved to index', :create_index!, :create_index
  include_examples 'backend operation moved to index', :close!, :close
  include_examples 'backend operation moved to index', :close, :close
  include_examples 'backend operation moved to index', :open!, :open
  include_examples 'backend operation moved to index', :open, :open
  include_examples 'backend operation moved to index', :refresh, :refresh
  include_examples 'backend operation moved to index', :refresh!, :refresh
  include_examples 'backend operation moved to index', :delete_index, :delete_index
  include_examples 'backend operation moved to index', :delete_index!, :delete_index
  include_examples 'backend operation moved to index', :create_index, :create_index
  include_examples 'backend operation moved to index', :create_index!, :create_index
  include_examples 'backend operation moved to index', :update_mapping, :update_mapping
  include_examples 'backend operation moved to index', :update_mapping!, :update_mapping
  include_examples 'backend operation moved to index', :update_settings, :update_settings
  include_examples 'backend operation moved to index', :update_settings!, :update_settings
  include_examples 'backend operation moved to index', :reset_index!, :reset_index
  include_examples 'backend operation moved to index', :import!, :import
  include_examples 'backend operation moved to index', :import, :import
  include_examples 'backend operation moved to index', :bulk!, :bulk
  include_examples 'backend operation moved to index', :bulk, :bulk
  include_examples 'backend operation moved to index', :index!, :index
  include_examples 'backend operation moved to index', :index, :index
  include_examples 'backend operation moved to index', :update!, :update
  include_examples 'backend operation moved to index', :update, :update
  include_examples 'backend operation moved to index', :delete!, :delete
  include_examples 'backend operation moved to index', :delete, :delete
  include_examples 'backend operation moved to index', :count, :count
  include_examples 'backend operation moved to index', :exist?, :exist?
  include_examples 'backend operation moved to index', :find!, :get
  include_examples 'backend operation moved to index', :find, :get
end
