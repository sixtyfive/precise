# frozen_string_literal: true

require_relative 'lib/precise/version'

Gem::Specification.new do |spec|
  spec.name = 'precise'
  spec.version = Precise::VERSION
  spec.authors = ['J. R. Schmid']
  spec.email = ['jrs+git@weitnahbei.de']

  spec.summary = 'Arabic to DMG-like (but more precise) and back'
  spec.description = 'Romanise Arabic script, arabicise romanisations of Arabic script back into Latin script '
  spec.homepage = 'https://rubygems.org/gems/precise'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sixtyfive/precise.git'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # dependencies

  spec.add_dependency 'slop'
  spec.add_dependency 'tiny_color'
end
