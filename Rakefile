# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "rubocop/rake_task"
require "jekyll"
require "fileutils"
require_relative "lib/asciidoctor/html"

JEKYLL_SITEDIR = "#{__dir__}/_site".freeze
JEKYLL_CSSDIR = "#{JEKYLL_SITEDIR}/assets/css".freeze
WWW_DIR = "#{__dir__}/www".freeze
WWW_ASSETS_DIR = "#{WWW_DIR}/#{Asciidoctor::Html::ASSETS_PATH}".freeze

Minitest::TestTask.create

RuboCop::RakeTask.new

task jekyll: %i[test rubocop] do
  config = Jekyll.configuration({
                                  source: "#{__dir__}/docs/jekyll",
                                  destination: JEKYLL_SITEDIR
                                })
  site = Jekyll::Site.new(config)
  Jekyll::Commands::Build.build site, config
end

task stylesheet: %i[jekyll] do
  FileUtils.mkdir_p WWW_ASSETS_DIR, verbose: true
  FileUtils.cp_r JEKYLL_CSSDIR, WWW_ASSETS_DIR, verbose: true
end

task default: %i[test rubocop]
