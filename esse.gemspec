# frozen_string_literal: true

require_relative 'lib/esse/version'

Gem::Specification.new do |spec|
  spec.name          = 'esse'
  spec.version       = Esse::VERSION
  spec.authors       = ['Marcos G. Zimmermann']
  spec.email         = ['mgzmaster@gmail.com']

  spec.summary       = %[Pure Ruby toolkit based on official elasticsearch-ruby library. (No! It isn't a new DSL)]
  spec.description   = 'All the elegance of ruby with the elasticsearch flexibility. This gem is a pretty simple ' \
                       'but excential helpers to deal with mapping, indexing, serialization and search.'
  spec.homepage      = 'https://github.com/marcosgz/esse'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/marcosgz/esse'
  spec.metadata['changelog_uri'] = 'https://github.com/marcosgz/esse/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'elasticsearch'
  spec.add_dependency 'multi_json'
  spec.add_dependency 'thor', '>= 0.19'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'yard', '~> 0.8.7.6'
end
