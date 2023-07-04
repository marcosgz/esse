# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable convention:RSpec/FilePath
RSpec.describe Esse::Repository, 'deprecations' do
  describe '.type_name' do
    before do
      stub_index(:comments) do
        repository :comment, const: true
      end
    end

    specify do
      Gem::Deprecate.skip_during do
        expect(CommentsIndex::Comment.type_name).to eq('comment')
      end
    end
  end

  describe '.mappings' do
    before do
      stub_index(:comments) do
        repository :comment, const: true
      end
    end

    specify do
      expect(CommentsIndex::Comment).to respond_to(:mappings)
      Gem::Deprecate.skip_during do
        expect {
          CommentsIndex::Comment.mappings do
            {
              properties: { age: { type: :integer }}
            }
          end
        }.to change { CommentsIndex.mappings_hash }.from({ mappings: {} }).to(
          mappings: { properties: { age: { type: :integer } } }
        )
      end
    end
  end

  describe '.backend' do
    before do
      stub_index(:comments) do
        repository :comment, const: true
      end
    end

    specify do
      Gem::Deprecate.skip_during do
        expect(CommentsIndex::Comment.backend).to be_an_instance_of(Esse::Deprecations::RepositoryBackendDelegator)
      end
    end
  end

  describe '.elasticsearch' do
    before do
      stub_index(:comments) do
        repository :comment, const: true
      end
    end

    specify do
      Gem::Deprecate.skip_during do
        expect(CommentsIndex::Comment.elasticsearch).to be_an_instance_of(Esse::Deprecations::RepositoryBackendDelegator)
      end
    end
  end

  describe '.serializer' do
    before do
      stub_index(:comments) do
        repository :comment, const: true
      end
    end

    specify do
      expect(CommentsIndex::Comment).to receive(:document).and_call_original
      expect {
        Gem::Deprecate.skip_during do
          CommentsIndex::Comment.serializer do |object, **_ctx|
            { id: object.id, name: object.name }
          end
        end
      }.to change { CommentsIndex::Comment.instance_variable_get(:@document_proc) }.from(nil).to(an_instance_of(Proc))
    end
  end
end
