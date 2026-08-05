# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: :rubocop

task :setup do
  sh "bash bin/setup"
end

desc "Release to rubygem.org"
task :release do
  # Run Build
  sh "gem build jekyll-shiki.gemspec"
  sh "bash bin/publish"
end
