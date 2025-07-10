# frozen_string_literal: true

require "optparse"
require "psych"
require "pathname"
require "fileutils"
require_relative "book"

module Asciidoctor
  module Html
    # The command line interface
    module CLI
      DEFAULT_OPTIONS = {
        "config-file": "config.yml",
        watch: false
      }.freeze

      DEFAULT_DIRS = {
        "srcdir" => ".",
        "outdir" => "www"
      }.freeze

      def self.parse_opts
        options = DEFAULT_OPTIONS.dup
        OptionParser.new do |parser|
          parser.on("-w", "--watch",
                    "Watch for file changes in SRCDIR. Default: unset")
          parser.on("-c", "--config-file CONFIG",
                    "Location of config file. Default: #{options[:"config-file"]}")
        end.parse!(into: options)
        options
      end

      def self.read_config(config_file)
        config = Psych.safe_load_file config_file
        config_dir = Pathname(config_file).dirname
        %w[outdir srcdir].each do |prop|
          config[prop] = "#{config_dir}/#{config[prop] || DEFAULT_DIRS[prop]}"
        end
        %w[chapters appendices].each do |prop|
          config[prop] &&= config[prop].map { |f| "#{config_dir}/#{f}" }
        end
        config
      end

      def self.setup_outdir(outdir)
        FileUtils.mkdir outdir unless File.directory?(outdir)
        assets_path = File.absolute_path ASSETS_PATH, "#{__dir__}/../../.."
        FileUtils.cp_r assets_path, outdir unless File.directory?("#{outdir}/#{ASSETS_PATH}")
      end

      def self.run
        opts = parse_opts
        config = read_config opts[:"config-file"]
        book_opts = {}
        %i[title author date chapname].each do |opt|
          key = opt.to_s
          book_opts[opt] = config[key] if config.include?(key)
        end
        book = Book.new(book_opts)
        setup_outdir config["outdir"]
        book.write config["chapters"], config["appendices"], config["outdir"]
      end
    end
  end
end
