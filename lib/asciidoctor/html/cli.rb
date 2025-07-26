# frozen_string_literal: true

require "fileutils"
require "filewatcher"
require "optparse"
require "pathname"
require "psych"
require_relative "book"
require_relative "webmanifest"

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
        begin
          config = Psych.safe_load_file config_file
        rescue StandardError
          puts "Error opening configuration file #{config_file}"
          exit 1
        end
        config_dir = Pathname(config_file).dirname
        %w[outdir srcdir].each do |prop|
          config[prop] = File.expand_path(config[prop] || DEFAULT_DIRS[prop], config_dir)
        end
        %w[chapters appendices].each do |prop|
          config[prop] &&= config[prop].map do |f|
            File.expand_path(f, config_dir)
          end
        end
        config
      end

      def self.setup_outdir(outdir)
        assets_dir = "#{outdir}/#{ASSETS_PATH}"
        FileUtils.mkdir_p assets_dir unless File.directory?(assets_dir)
        rootdir = File.absolute_path "#{__dir__}/../../.."
        %W[#{CSS_PATH} #{FAVICON_PATH}].each do |p|
          dir = "#{outdir}/#{p}"
          next if Dir.exist?(dir)

          puts "Generating #{dir}"
          FileUtils.cp_r "#{rootdir}/#{p}", assets_dir
        end
      end

      def self.generate_webmanifest(outdir, name, short_name)
        filename = "#{outdir}/#{FAVICON_PATH}/site.webmanifest"
        puts "Generating #{filename}"
        File.write filename, Webmanifest.generate(name, short_name)
      end

      def self.run(opts = nil)
        opts ||= parse_opts
        config = read_config opts[:"config-file"]
        outdir = config["outdir"]
        book_opts = {}
        %i[title short_title author date se_id chapname].each do |opt|
          key = opt.to_s
          book_opts[opt] = config[key] if config.include?(key)
        end
        book_opts[:short_title] ||= book_opts[:title]
        setup_outdir outdir
        generate_webmanifest outdir, book_opts[:title], book_opts[:short_title]
        book = Book.new book_opts
        puts "Writing book to #{outdir}"
        book.write config["chapters"], config["appendices"], config["outdir"]
        return unless opts[:watch]

        Filewatcher.new("#{config["srcdir"]}/*.adoc").watch do |changes|
          chapters = []
          appendices = []
          changes.each_key do |filename|
            puts "Detected change in #{filename}"
            chapters.append(filename) if config["chapters"].include?(filename)
            appendices.append(filename) if config["appendices"].include?(filename)
          end
          puts "Regenerating book:"
          puts "    Chapters: #{chapters.map { |c| Pathname(c).basename }.join ", "}" unless chapters.empty?
          puts "    Appendices: #{appendices.map { |a| Pathname(a).basename }.join ", "}" unless appendices.empty?
          book.write chapters, appendices, config["outdir"]
        end
      end
    end
  end
end
