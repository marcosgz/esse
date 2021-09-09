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

    it 'generates the mappings template for each type' do
      expected_filename = Esse.config.indices_directory.join('users_index/templates/user_mapping.json')

      expect_generate(%w[index users user], expected_filename)
    end

    it 'generates a serializer for each type' do
      expected_filename = Esse.config.indices_directory.join('users_index/serializers/user_serializer.rb')

      expect_generate(%w[index users user], expected_filename)
      expect_contains(expected_filename, <<~CODE
        class UsersIndex < Esse::Index
          module Serializers
            class UserSerializer
      CODE
      )
    end

    it 'generates a new index class with namespace' do
      expected_filename = Esse.config.indices_directory.join('v1/users_index.rb')

      expect_generate(%w[index v1/users user], expected_filename)
      expect_contains(expected_filename, 'class V1::UsersIndex < Esse::Index')
    end

    it 'generates the mappings template for each type using an index class with namespace' do
      expected_filename = Esse.config.indices_directory.join('v1/users_index/templates/user_mapping.json')

      expect_generate(%w[index v1/users user], expected_filename)
    end

    it 'generates a serializer for each type under a namespace' do
      expected_filename = Esse.config.indices_directory.join('v1/users_index/serializers/user_serializer.rb')

      expect_generate(%w[index v1/users user], expected_filename)
      expect_contains(expected_filename, <<~CODE
        class V1::UsersIndex < Esse::Index
          module Serializers
            class UserSerializer
      CODE
      )
    end
  end
end
