# frozen_string_literal: true

require 'spec_helper'
require 'support/collections'

RSpec.describe Esse::Repository do
  describe '.collection' do
    specify do
      expect {
        Class.new(Esse::Index) do
          repository :foo do
            collection do
            end
          end
        end
      }.not_to raise_error
    end

    specify do
      klass = Class.new(Esse::Index) do
        repository :foo do
          collection do |&b|
            b.call([])
          end
        end
      end
      expect(klass.repo(:foo).collection_class).to be(nil)

      proc = klass.instance_variable_get(:@collection_proc)
      expect { |b| proc.call(&b).to yield_with_args([]) }
    end

    specify do
      expect {
        Class.new(Esse::Index) do
          repository :foo do
            collection
          end
        end
      }.to raise_error(ArgumentError)
    end

    specify do
      klass = Class.new(Esse::Index) do
        repository :foo do
          collection DummyGeosCollection
        end
      end
      expect(klass.repo(:foo).collection_class).to be(DummyGeosCollection)

      col_proc = klass.repo(:foo).instance_variable_get(:@collection_proc)
      expect(col_proc).to eq(DummyGeosCollection)
    end

    it 'raises an error if the collection does not implement Enumerable interface' do
      collection_klass = Class.new
      expect {
        Class.new(Esse::Index) do
          repository :foo do
            collection collection_klass
          end
        end
      }.to raise_error(ArgumentError)
    end
  end

  describe '.each_batch' do
    context 'without the collection definition' do
      before do
        stub_index(:users) do
          repository(:user) {}
        end
      end

      specify do
        expect {
          UsersIndex::User.send(:each_batch) { |batch| puts batch }
        }.to raise_error(NotImplementedError, 'there is no "user" collection defined for the "UsersIndex" index')
      end
    end

    context 'without collection data' do
      before do
        stub_index(:users) do
          repository :user do
            collection do
            end
          end
        end
      end

      it 'does not raise any exception' do
        expect { |b| UsersIndex::User.send(:each_batch, &b) }.not_to yield_control
      end
    end

    context 'with the collection definition' do
      before do
        stub_index(:users) do
          repository :user do
            collection do |**opts, &block|
              [[{id: 1}], [{id: 2}], [{id: 3}]].each do |batch|
                block.call batch, opts
              end
            end
          end
        end
      end

      it 'yields each block with arguments' do
        o = { active: true }
        expect { |b| UsersIndex::User.send(:each_batch, **o, &b) }.to yield_successive_args(
          [[{id: 1}], o],
          [[{id: 2}], o],
          [[{id: 3}], o]
        )
      end
    end

    context 'with a collection class' do
      let(:ids) { (1..6).to_a }
      let(:repo) do
        ids.map do |id|
          { id: id }
        end
      end

      before do
        stub_index(:geos) do
          repository :city do
            collection DummyGeosCollection
          end
        end
      end

      it 'yields each block with arguments' do
        f = { active: true }
        o = { repo: repo, batch_size: 2 }.merge(f)
        expect { |b| GeosIndex::City.send(:each_batch, **o, &b) }.to yield_successive_args(
          [[{id: 1}, {id: 2}], f],
          [[{id: 3}, {id: 4}], f],
          [[{id: 5}, {id: 6}], f]
        )
      end
    end
  end

  describe '.each_batch_ids' do
    context 'without the collection definition' do
      before do
        stub_index(:users) do
          repository(:user) {}
        end
      end

      specify do
        expect {
          UsersIndex::User.each_batch_ids { |batch| puts batch }
        }.to raise_error(NotImplementedError, 'there is no "user" collection defined for the "UsersIndex" index')
      end
    end

    context 'without collection data' do
      before do
        stub_index(:users) do
          repository :user do
            collection do
            end
          end
        end
      end

      it 'returns an enumerator' do
        expect(Kernel).to receive(:warn).with(a_string_matching("The `#each' method will be used instead, which may lead to performance degradation")).and_return(nil)

        expect(UsersIndex::User.each_batch_ids).to be_a(Enumerator)
      end

      it 'does not raise any exception' do
        expect(Kernel).to receive(:warn).with(a_string_matching("The `#each' method will be used instead, which may lead to performance degradation")).and_return(nil)

        expect { |b| UsersIndex::User.each_batch_ids(&b) }.not_to yield_control
      end
    end

    context 'with the collection definition' do
      let(:logger) { instance_double(::Logger) }

      before do
        stub_index(:users) do
          repository :user do
            collection do |**opts, &block|
              [[{id: 1}], [{id: 2}], [{id: 3}]].each do |batch|
                block.call batch, opts
              end
            end

            document do |hash, **opts|
              Esse::HashDocument.new(hash)
            end
          end
        end
        allow(::Esse).to receive(:logger).and_return(logger)
      end

      it 'retuns an enumerator' do
        expect(Kernel).to receive(:warn).with(a_string_matching("The `#each' method will be used instead, which may lead to performance degradation")).and_return(nil)

        expect(UsersIndex::User.each_batch_ids).to be_a(Enumerator)
      end

      it "warns user for performance degradation and yields serialized ids" do
        expect(Kernel).to receive(:warn).with(a_string_matching("The `#each' method will be used instead, which may lead to performance degradation")).and_return(nil)

        o = { active: true }
        expect { |b| UsersIndex::User.each_batch_ids(**o, &b) }.to yield_successive_args([1], [2], [3])
      end
    end

    context 'with a collection class' do
      let(:ids) { (1..6).to_a }
      let(:repo) do
        ids.map do |id|
          { id: id, name: "City #{id}", active: true }
        end
      end

      before do
        stub_index(:geos) do
          repository :city do
            collection DummyGeosCollection
          end
        end
      end

      it 'returns an enumerator' do
        expect(GeosIndex::City.each_batch_ids(repo: repo, batcch_size: 2)).to be_a(Enumerator)
      end

      it 'yields each block with arguments' do
        f = { active: true }
        o = { repo: repo, batch_size: 2 }.merge(f)
        expect { |b| GeosIndex::City.each_batch_ids(**o, &b) }.to yield_successive_args([1, 2], [3, 4], [5, 6])
      end
    end
  end
end
