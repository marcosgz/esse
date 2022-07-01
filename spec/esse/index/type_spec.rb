# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index do
  describe '.define_type' do
    specify do
      index = Class.new(Esse::Index) { define_type :user, constant: true }
      expect(index::User.superclass).to eq(Esse::IndexType)
    end

    specify do
      index = Class.new(Esse::Index) { define_type :user }
      expect(index.repo(:user).superclass).to eq(Esse::IndexType)
    end

    context 'with a underscored type' do
      before do
        stub_index(:events) { define_type :schedule_occurrence, constant: true }
      end

      specify do
        expect(EventsIndex.type_hash.values).to eq([EventsIndex::ScheduleOccurrence])
      end
    end

    context 'with a class under under namespace' do
      before do
        stub_class('Namespace::Event')
        stub_index(:events) { define_type Namespace::Event, constant: true }
      end

      specify do
        expect(EventsIndex.type_hash.values).to eq([EventsIndex::Event])
      end
    end

    context 'index type_hash' do
      before do
        stub_index(:users) do
          define_type :admin, constant: true
          define_type :editorial, constant: true
        end
      end

      specify do
        expect(UsersIndex.type_hash.keys).to match_array(%w[admin editorial])
        expect(UsersIndex.type_hash['admin']).to eq(UsersIndex::Admin)
        expect(UsersIndex.type_hash['editorial']).to eq(UsersIndex::Editorial)
      end
    end

    context 'type singleton methods' do
      before do
        stub_index(:events) { define_type :event, constant: true }
      end

      specify do
        expect(EventsIndex::Event.index).to eq(EventsIndex)
      end

      specify do
        expect(EventsIndex::Event.type_name).to eq('event')
      end
    end
  end

  describe '.repo' do
    it 'raise an error when calling without arguments when no type is defined' do
      stub_index(:events)
      expect { EventsIndex.repo }.to raise_error(ArgumentError).with_message(
        /No repo named "__default__" found. Use the `repository' method to define one/
      )
    end

    it 'raise an error when calling with repo name when no type is defined' do
      stub_index(:events)
      expect { EventsIndex.repo(:event) }.to raise_error(ArgumentError).with_message(
        /No repo named "event" found. Use the `repository' method to define one/
      )
    end

    it 'returns the first defined when calling with arguments' do
      stub_index(:events) { define_type :event, constant: true }
      expect(EventsIndex.repo).to eq(EventsIndex::Event)
    end

    it 'raises an error when calling repo without arguments in index with multiple repos' do
      stub_index(:events) do
        define_type :event, constant: true
        define_type :place, constant: true
      end

      expect { EventsIndex.repo }.to raise_error(ArgumentError).with_message(
        /You can only call `repo' with a name when there is only one type defined./
      )
    end

    it 'returns the correct repo when calling repo with arguments in index with multiple repos' do
      stub_index(:events) do
        define_type :event, constant: true
        define_type :place, constant: true
      end

      expect(EventsIndex.repo(:event)).to eq(EventsIndex::Event)
      expect(EventsIndex.repo(:place)).to eq(EventsIndex::Place)
      expect(EventsIndex.repo('event')).to eq(EventsIndex::Event)
    end
  end
end
