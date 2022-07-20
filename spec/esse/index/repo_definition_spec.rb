# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index do
  describe '.repository' do
    specify do
      index = Class.new(Esse::Index) { repository :user, const: true }
      expect(index::User.superclass).to eq(Esse::Repository)
    end

    specify do
      index = Class.new(Esse::Index) { repository :user }
      expect(index.repo(:user).superclass).to eq(Esse::Repository)
    end

    it 'allows define document_type' do
      index = Class.new(Esse::Index) { repository :user, document_type: :foo }
      expect(index.repo(:user).document_type).to eq('foo')
    end

    context 'with a underscored type' do
      before do
        stub_index(:events) { repository :schedule_occurrence, const: true }
      end

      specify do
        expect(EventsIndex.repo_hash.values).to eq([EventsIndex::ScheduleOccurrence])
      end
    end

    context 'with a class under under namespace' do
      before do
        stub_class('Namespace::Event')
        stub_index(:events) { repository Namespace::Event, const: true }
      end

      specify do
        expect(EventsIndex.repo_hash.values).to eq([EventsIndex::Event])
      end
    end

    context 'index repo_hash' do
      before do
        stub_index(:users) do
          repository :admin, const: true
          repository :editorial, const: true
        end
      end

      specify do
        expect(UsersIndex.repo_hash.keys).to match_array(%w[admin editorial])
        expect(UsersIndex.repo_hash['admin']).to eq(UsersIndex::Admin)
        expect(UsersIndex.repo_hash['editorial']).to eq(UsersIndex::Editorial)
      end
    end

    context 'type singleton methods' do
      before do
        stub_index(:events) { repository :event, const: true }
      end

      specify do
        expect(EventsIndex::Event.index).to eq(EventsIndex)
      end

      specify do
        expect(EventsIndex::Event.document_type).to eq('event')
      end

      specify do
        expect(EventsIndex::Event.repo_name).to eq('event')
      end
    end
  end

  describe '.repo' do
    it 'raise an error when calling without arguments when no type is defined' do
      stub_index(:events)
      expect { EventsIndex.repo }.to raise_error(ArgumentError).with_message(
        /No repo named "default" found. Use the `repository' method to define one/
      )
    end

    it 'raise an error when calling with repo name when no type is defined' do
      stub_index(:events)
      expect { EventsIndex.repo(:event) }.to raise_error(ArgumentError).with_message(
        /No repo named "event" found. Use the `repository' method to define one/
      )
    end

    it 'returns the first defined when calling with arguments' do
      stub_index(:events) { repository :event, const: true }
      expect(EventsIndex.repo).to eq(EventsIndex::Event)
    end

    it 'raises an error when calling repo without arguments in index with multiple repos' do
      stub_index(:events) do
        repository :event, const: true
        repository :place, const: true
      end

      expect { EventsIndex.repo }.to raise_error(ArgumentError).with_message(
        /You can only call `repo' with a name when there is only one type defined./
      )
    end

    it 'returns the correct repo when calling repo with arguments in index with multiple repos' do
      stub_index(:events) do
        repository :event, const: true
        repository :place, const: true
      end

      expect(EventsIndex.repo(:event)).to eq(EventsIndex::Event)
      expect(EventsIndex.repo(:place)).to eq(EventsIndex::Place)
      expect(EventsIndex.repo('event')).to eq(EventsIndex::Event)
    end
  end

  describe '.repo?' do
    it 'returns false when no type is defined' do
      stub_index(:events)
      expect(EventsIndex.repo?).to eq(false)
    end

    context 'with a repo defined' do
      before do
        stub_index(:events) { repository :event, const: false }
      end

      it { expect(EventsIndex.repo?).to eq(true) }
      it { expect(EventsIndex.repo?('event')).to eq(true) }
      it { expect(EventsIndex.repo?(:event)).to eq(true) }
      it { expect(EventsIndex.repo?(Esse::DEFAULT_REPO_NAME)).to eq(false) }
    end
  end
end
