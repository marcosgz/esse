# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::IndexType do
  describe '.collection' do
    specify do
      expect {
        Class.new(Esse::IndexType) do
          collection do
          end
        end
      }.not_to raise_error
    end

    specify do
      klass = Class.new(Esse::IndexType) do
        collection do |&b|
          b.call([])
        end
      end

      proc = klass.instance_variable_get(:@collection_proc)
      expect { |b| proc.call(&b).to yield_with_args([]) }
    end

    specify do
      expect {
        Class.new(Esse::IndexType) do
          collection
        end
      }.to raise_error(SyntaxError)
    end
  end

  describe '.each_batch' do
    context 'without the collection definition' do
      before do
        stub_index(:users) do
          define_type(:user) {}
        end
      end

      specify do
        expect {
          UsersIndex::User.each_batch { |batch| puts batch }
        }.to raise_error(NotImplementedError, 'there is no collection defined for the "UsersIndex::User" index')
      end
    end

    context 'without collection data' do
      before do
        stub_index(:users) do
          define_type :user do
            collection do
            end
          end
        end
      end

      it 'does not raise any exception' do
        expect { |b| UsersIndex::User.each_batch(&b) }.not_to yield_control
      end
    end

    context 'with the collection definition' do
      before do
        stub_index(:users) do
          define_type :user do
            collection do |opts, &block|
              [[1], [2], [3]].each do |batch|
                block.call batch, opts
              end
            end
          end
        end
      end

      it 'yields each block with arguments' do
        o = { active: true }
        expect { |b| UsersIndex::User.each_batch(o, &b) }.to yield_successive_args([[1], o], [[2], o], [[3], o])
      end
    end
  end
end
