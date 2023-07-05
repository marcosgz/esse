# frozen_string_literal: true

require 'spec_helper'
require 'support/cli_helpers'

RSpec.describe Esse::CLI::Generate, type: :cli do
  describe '.index' do
    it 'generates a index with multiple types' do
      expected_filename = Esse.config.indices_directory.join('users_index.rb')

      expect_generate(%w[index users admin normal], expected_filename)
      expect_contains(expected_filename, 'class UsersIndex < Esse::Index')
      expect_contains(expected_filename, 'repository :admin do')
      expect_contains(expected_filename, 'repository :normal do')
    end

    it 'does NOT generates the mappings template for each repo' do
      expected_filename = Esse.config.indices_directory.join('users_index/templates/mappings.json')

      expect_generate(%w[index users user --mappings], expected_filename)
    end

    it 'generates a document for each respository type' do
      expected_filename = Esse.config.indices_directory.join('users_index/documents/user_document.rb')

      expect_generate(%w[index users user --documents], expected_filename)
      expect_contains(expected_filename, <<~CODE
        class UsersIndex < Esse::Index
          module Documents
            class UserDocument < Esse::Document
      CODE
      )
    end

    it 'generates a new index class with namespace' do
      expected_filename = Esse.config.indices_directory.join('v1/users_index.rb')

      expect_generate(%w[index v1/users user], expected_filename)
      expect_contains(expected_filename, 'class V1::UsersIndex < Esse::Index')
    end

    it 'generates a new index class when passing ruby class as argument' do
      expected_filename = Esse.config.indices_directory.join('ver_one/users_index.rb')

      expect_generate(%w[index VerOne::Users user], expected_filename)
      expect_contains(expected_filename, 'class VerOne::UsersIndex < Esse::Index')
    end

    it 'generates a document for each repository type under a namespace' do
      expected_filename = Esse.config.indices_directory.join('v1/users_index/documents/user_document.rb')

      expect_generate(%w[index v1/users user --documents], expected_filename)
      expect_contains(expected_filename, <<~CODE
        class V1::UsersIndex < Esse::Index
          module Documents
            class UserDocument < Esse::Document
      CODE
      )
    end

    it 'generates index with the cluster_id' do
      expected_filename = Esse.config.indices_directory.join('users_index.rb')
      expect_generate(%w[index users user --cluster_id=v2], expected_filename)
      expect_contains(expected_filename, <<~CODE
        class UsersIndex < Esse::Index
          self.cluster_id = :v2
      CODE
      )
    end
  end
end
