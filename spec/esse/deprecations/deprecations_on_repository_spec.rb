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
