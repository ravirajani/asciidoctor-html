# frozen_string_literal: true

require "autoprefixer-rails"
require "bundler/gem_tasks"
require "minitest/test_task"
require "rubocop/rake_task"
require "jekyll"
require "fileutils"
require_relative "lib/asciidoctor/html"

JEKYLL_SITEDIR = "#{__dir__}/docs/html/_site".freeze
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

task autoprefix: %i[jekyll] do
  filename = "#{JEKYLL_CSSDIR}/styles.css"
  css = File.read filename
  prefixed = AutoprefixerRails.process css
  File.write filename, prefixed
end

task stylesheet: %i[autoprefix] do
  FileUtils.mkdir_p Asciidoctor::Html::CSS_PATH, verbose: true
  FileUtils.cp_r JEKYLL_CSSDIR, Asciidoctor::Html::ASSETS_PATH, verbose: true
end

task default: %i[test rubocop]
