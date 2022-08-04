# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable convention:RSpec/FilePath
RSpec.describe Esse::Repository, '.type_name' do
  describe do
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
end

RSpec.describe Esse::Repository, '.mappings' do
  describe do
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
end
