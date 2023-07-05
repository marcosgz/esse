# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'deprecations' do
  describe 'Esse::Index.define_type' do
    specify do
      Gem::Deprecate.skip_during do
        index = Class.new(Esse::Index) { define_type :user }
        expect(index.repo(:user).superclass).to eq(Esse::Repository)
      end
    end
  end

  describe 'Esse::Index.type_hash' do
    before do
      stub_index(:posts)
      stub_index(:comments) do
        repository :comment
      end
    end

    specify do
      Gem::Deprecate.skip_during do
        expect(PostsIndex.type_hash).to eq({})
      end
    end

    specify do
      Gem::Deprecate.skip_during do
        expect(CommentsIndex.type_hash.keys).to eq(['comment'])
      end
    end
  end

  describe 'Esse::Index.index_version' do
    let(:index) { Class.new(Esse::Index) }
    specify do
      expect(index).to receive(:index_suffix).once.and_return('v1')
      Gem::Deprecate.skip_during do
        expect(index.index_version).to eq('v1')
      end
    end
  end

  describe 'Esse::Index.index_version=' do
    let(:index) { Class.new(Esse::Index) }

    specify do
      expect(index).to receive(:index_suffix=).once.with('v1').and_call_original
      Gem::Deprecate.skip_during do
        index.index_version = 'v1'
      end

      expect(index.index_suffix).to eq('v1')
    end
  end

  describe '.backend' do
    specify do
      c = Class.new(Esse::Index)
      Gem::Deprecate.skip_during do
        expect(c.backend).to be_an_instance_of(Esse::Deprecations::IndexBackendDelegator)
      end
    end
  end

  describe '.elasticsearch' do
    specify do
      c = Class.new(Esse::Index)
      Gem::Deprecate.skip_during do
        expect(c.elasticsearch).to be_an_instance_of(Esse::Deprecations::IndexBackendDelegator)
      end
    end
  end
end
