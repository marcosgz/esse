# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'deprecations' do
  before do
    stub_index(:posts) do
      repository :post, const: true
    end
  end

  shared_examples 'backend operation moved to index' do |outdated, replacement|
    describe "Esse::Repository.backend.#{outdated} moved to Esse::Index.#{replacement}" do
      specify do
        expect(PostsIndex).to receive(replacement).and_return(:ok)
        Gem::Deprecate.skip_during do
          expect(PostsIndex::Post.backend.send(outdated)).to eq(:ok)
        end
      end
    end

    describe "Esse::Repository.elasticsearch.#{outdated} moved to Esse::Index.#{replacement}" do
      specify do
        expect(PostsIndex).to receive(replacement).and_return(:ok)
        Gem::Deprecate.skip_during do
          expect(PostsIndex::Post.elasticsearch.send(outdated)).to eq(:ok)
        end
      end
    end
  end

  shared_examples 'backend operation moved to repository' do |outdated, replacement|
    describe "Esse::Repository.backend.#{outdated} moved to Esse::Repository.#{replacement}" do
      specify do
        expect(PostsIndex::Post).to receive(replacement).and_return(:ok)
        Gem::Deprecate.skip_during do
          expect(PostsIndex::Post.backend.send(outdated)).to eq(:ok)
        end
      end
    end

    describe "Esse::Repository.elasticsearch.#{outdated} moved to Esse::Repository.#{replacement}" do
      specify do
        expect(PostsIndex::Post).to receive(replacement).and_return(:ok)
        Gem::Deprecate.skip_during do
          expect(PostsIndex::Post.elasticsearch.send(outdated)).to eq(:ok)
        end
      end
    end
  end

  include_examples 'backend operation moved to repository', :import, :import
  include_examples 'backend operation moved to repository', :import!, :import
  include_examples 'backend operation moved to index', :bulk!, :bulk
  include_examples 'backend operation moved to index', :bulk, :bulk
  include_examples 'backend operation moved to index', :index!, :index
  include_examples 'backend operation moved to index', :index, :index
  include_examples 'backend operation moved to index', :index_document, :index
  include_examples 'backend operation moved to index', :update!, :update
  include_examples 'backend operation moved to index', :update, :update
  include_examples 'backend operation moved to index', :delete!, :delete
  include_examples 'backend operation moved to index', :delete, :delete
  include_examples 'backend operation moved to index', :delete_document, :delete
  include_examples 'backend operation moved to index', :count, :count
  include_examples 'backend operation moved to index', :exist?, :exist?
  include_examples 'backend operation moved to index', :find!, :get
  include_examples 'backend operation moved to index', :find, :get
end
