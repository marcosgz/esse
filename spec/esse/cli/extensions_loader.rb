# frozen_string_literal: true

require 'spec_helper'
require 'esse/cli/extensions_loader'

RSpec.describe Esse::CLI::ExtensionsLoader do
  describe '.load!' do
    subject { described_class.load! }

    it 'requires esse-rails' do
      expect { subject }.to require_gem('esse-rails')
    end

    it 'requires esse-active_record' do
      expect { subject }.to require_gem('esse-active_record')
    end

    it 'requires esse-sequel' do
      expect { subject }.to require_gem('esse-sequel')
    end

    it 'requires esse-kaminari' do
      expect { subject }.to require_gem('esse-kaminari')
    end
  end

  def require_gem(gem_name)
    raise_error(LoadError, /#{gem_name}/)
  end
end
