# frozen_string_literal: true

require 'bundler'
Bundler.require

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_*.rb']
end

desc 'increase minor version number by one'
task :bump do
  current = Precise::VERSION
  new = current.split('.')
  new[-1] = (new[-1].to_i+1).to_s
  new = new.join('.')
  version_file = 'lib/precise/version.rb'
  File.write(version_file, File.read(version_file).gsub(current, new))
end

task :default do; system 'rake -T'; end
