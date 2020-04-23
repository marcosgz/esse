# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index do
  describe '.define_type' do
    specify do
      index = Class.new(Esse::Index) { define_type :user }
      expect(index::User.superclass).to eq(Esse::IndexType)
    end

    context 'with a underscored type' do
      before do
        stub_index(:events) { define_type :schedule_occurrence }
      end

      specify do
        expect(EventsIndex.type_hash.values).to eq([EventsIndex::ScheduleOccurrence])
      end
    end

    context 'with a class under under namespace' do
      before do
        stub_class('Namespace::Event')
        stub_index(:events) { define_type Namespace::Event }
      end

      specify do
        expect(EventsIndex.type_hash.values).to eq([EventsIndex::Event])
      end
    end

    context 'index type_hash' do
      before do
        stub_index(:users) do
          define_type :admin
          define_type :editorial
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
        stub_index(:events) { define_type :event }
      end

      specify do
        expect(EventsIndex::Event.index).to eq(EventsIndex)
      end

      specify do
        expect(EventsIndex::Event.type_name).to eq('event')
      end
    end
  end
end
