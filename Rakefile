# frozen_string_literal: true

require "bundler/gem_tasks"
require "jekyll"
require "minitest/test_task"

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new

task build: %i[test rubocop] do
  config = Jekyll.configuration({
    source: "./docs",
    destination: "./_site"
  })
  site = Jekyll::Site.new(config)
  Jekyll::Commands::Build.build site, config
end

task default: %i[test rubocop]
