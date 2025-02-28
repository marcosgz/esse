# frozen_string_literal: true

require 'spec_helper'
require 'esse/cli/extensions_loader'

RSpec.describe Esse::CLI::ExtensionsLoader do
  describe '.load!' do
    subject(:load) { described_class.load! }

    before do
      allow(Kernel).to receive(:require)
    end

    it 'requires esse-rails' do
      expect(Kernel).to receive(:require).with('esse-rails').and_raise(LoadError) # rubocop:disable RSpec/StubbedMock
      expect { load }.not_to raise_error
    end

    it 'requires esse-active_record' do
      expect(Kernel).to receive(:require).with('esse-active_record').and_raise(LoadError) # rubocop:disable RSpec/StubbedMock
      expect { load }.not_to raise_error
    end

    it 'requires esse-sequel' do
      expect(Kernel).to receive(:require).with('esse-sequel').and_raise(LoadError) # rubocop:disable RSpec/StubbedMock
      expect { load }.not_to raise_error
    end

    it 'requires esse-kaminari' do
      expect(Kernel).to receive(:require).with('esse-kaminari').and_raise(LoadError) # rubocop:disable RSpec/StubbedMock
      expect { load }.not_to raise_error
    end

    it 'requires esse-pagy' do
      expect(Kernel).to receive(:require).with('esse-pagy').and_raise(LoadError) # rubocop:disable RSpec/StubbedMock
      expect { load }.not_to raise_error
    end

    it 'requires esse-will_paginate' do
      expect(Kernel).to receive(:require).with('esse-will_paginate').and_raise(LoadError) # rubocop:disable RSpec/StubbedMock
      expect { load }.not_to raise_error
    end

    it 'requires esse-jbuilder' do
      expect(Kernel).to receive(:require).with('esse-jbuilder').and_raise(LoadError) # rubocop:disable RSpec/StubbedMock
      expect { load }.not_to raise_error
    end

    it 'requires esse-redis_storage' do
      expect(Kernel).to receive(:require).with('esse-redis_storage').and_raise(LoadError) # rubocop:disable RSpec/StubbedMock
      expect { load }.not_to raise_error
    end

    it 'requires esse-async_indexing' do
      expect(Kernel).to receive(:require).with('esse-async_indexing').and_raise(LoadError) # rubocop:disable RSpec/StubbedMock
      expect { load }.not_to raise_error
    end
  end
end
