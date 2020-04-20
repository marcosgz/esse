# frozen_string_literal: true

require 'spec_helper'
require 'support/cli_helpers'

RSpec.describe Esse::CLI::Generate, type: :cli do
  describe '.index' do
    it 'generates a index with multiple types' do
      expected_filename = Esse.config.indices_directory.join('users_index.rb')

      expect_generate(%w[index users admin normal], expected_filename)
      expect_contains(expected_filename, 'class UsersIndex < Esse::Index')
      expect_contains(expected_filename, 'define_type :admin do')
      expect_contains(expected_filename, 'define_type :normal do')
    end

    it 'generates a new index class with namespace' do
      expected_filename = Esse.config.indices_directory.join('v1/users_index.rb')

      expect_generate(%w[index v1/users user], expected_filename)
      expect_contains(expected_filename, 'class V1::UsersIndex < Esse::Index')
    end
  end
end