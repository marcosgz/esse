# frozen_string_literal: true

require 'spec_helper'
require 'support/esse_config'

RSpec.describe Esse::TemplateLoader do
  describe '.read' do
    context 'from a JSON' do
      specify do
        stub_template(
          'test.json',
          '{"ok":true}',
        ) do |dir|
          loader = described_class.new(dir)
          expect(loader.read('test')).to eq('ok' => true)
          expect(loader.read('{test,test123}')).to eq('ok' => true)
          expect(loader.read('testing')).to eq(nil)
          expect(loader.read('subdir/test')).to eq(nil)
        end
      end
    end

    context 'from a YAML' do
      specify do
        stub_template(
          'test.yaml',
          'ok: true',
        ) do |dir|
          loader = described_class.new(dir)
          expect(loader.read('test')).to eq('ok' => true)
          expect(loader.read('{test,test123}')).to eq('ok' => true)
          expect(loader.read('testing')).to eq(nil)
          expect(loader.read('subdir/test')).to eq(nil)
        end
      end

      specify do
        stub_template(
          'test.yml',
          'ok: true',
        ) do |dir|
          loader = described_class.new([dir.to_s, 'tmp/dir2'])
          expect(loader.read('test')).to eq('ok' => true)
          expect(loader.read('{test,test123}')).to eq('ok' => true)
          expect(loader.read('testing')).to eq(nil)
          expect(loader.read('subdir/test')).to eq(nil)
        end
      end
    end
  end

  def stub_template(relative_filename, content, &block)
    dir = Pathname.new('tmp/templates_loader')

    # Cleanup
    FileUtils.rm_rf(dir)
    FileUtils.mkdir_p(dir)

    # Create a real file
    filename = dir.join(relative_filename)
    File.open(filename, 'w') { |f| f.write(content) }

    # Create a similar file
    other_file = filename.dirname.join("other#{filename.extname}")
    File.open(other_file, 'w') { |f| f.write('other') }

    block.call(dir)
  end
end
