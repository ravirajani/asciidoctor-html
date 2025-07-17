# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "rubocop/rake_task"
require "jekyll"
require "fileutils"
require_relative "lib/asciidoctor/html"

JEKYLL_SITEDIR = "#{__dir__}/_site".freeze
JEKYLL_CSSDIR = "#{JEKYLL_SITEDIR}/assets/css".freeze

Minitest::TestTask.create

RuboCop::RakeTask.new

task jekyll: %i[test rubocop] do
  config = Jekyll.configuration({
                                  source: "#{__dir__}/docs/html",
                                  destination: JEKYLL_SITEDIR
                                })
  site = Jekyll::Site.new(config)
  Jekyll::Commands::Build.build site, config
end

task stylesheet: %i[jekyll] do
  FileUtils.mkdir_p Asciidoctor::Html::CSS_PATH, verbose: true
  FileUtils.cp_r JEKYLL_CSSDIR, Asciidoctor::Html::ASSETS_PATH, verbose: true
end

task default: %i[test rubocop]
