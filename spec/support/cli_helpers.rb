# frozen_string_literal: true

require 'thor'
require 'fileutils'
require 'esse/cli'

module CliHelpers
  def self.included(base)
    base.before(:each) do
      Esse.config.indices_directory = 'tmp/indices'
      FileUtils.rm_rf(Esse.config.indices_directory)
    end

    base.after(:each) do
      reset_config!
    end
  end

  def cli_exec(command)
    quietly { Esse::CLI.start(command) }
  end

  def expect_contains(filename, content)
    expect(File.read(filename)).to include(content)
  end

  def expect_generate(command, location)
    expect { cli_exec(['generate', *command]) }.to change {
      File.exist?(location)
    }.from(false).to(true)
  end

  protected

  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(IO::NULL)
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
    old_stream.close
  end

  def quietly
    silence_stream(STDOUT) do
      silence_stream(STDERR) do
        yield
      end
    end
  end
end

RSpec.configure do |config|
  config.include CliHelpers, type: :cli
end
