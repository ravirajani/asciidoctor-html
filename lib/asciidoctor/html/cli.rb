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
          puts "Error opening configuration file\n  #{config_file}"
          puts
          exit 1
        end
        config_dir = Pathname(config_file).dirname
        %w[outdir srcdir].each do |prop|
          config[prop] = File.expand_path(config[prop] || DEFAULT_DIRS[prop], config_dir)
        end
        %w[chapters appendices].each do |prop|
          config[prop] ||= []
          config[prop] = config[prop].map do |f|
            File.expand_path(f, config_dir)
          end
        end
        config
      end

      def self.setup_outdir(srcdir, outdir)
        assets_out = "#{outdir}/#{ASSETS_PATH}"
        FileUtils.mkdir_p assets_out unless File.directory?(assets_out)
        %W[#{IMG_PATH} #{CSS_PATH} #{FAVICON_PATH}].each do |p|
          dir = "#{srcdir}/#{p}"
          next unless Dir.exist?(dir)

          puts "Copying\n  #{dir}\nto\n  #{assets_out}"
          puts
          FileUtils.cp_r dir, assets_out
        end
        rootdir = File.absolute_path "#{__dir__}/../../.."
        %W[#{CSS_PATH} #{FAVICON_PATH}].each do |p|
          dir = "#{outdir}/#{p}"
          next if Dir.exist?(dir)

          puts "Putting default '#{p}' files in\n  #{dir}"
          puts
          FileUtils.cp_r "#{rootdir}/#{p}", assets_out
        end
      end

      def self.generate_webmanifest(outdir, name, short_name)
        filename = "#{outdir}/#{FAVICON_PATH}/site.webmanifest"
        puts "Generating\n  #{filename}"
        puts
        File.write filename, Webmanifest.generate(name, short_name)
      end

      def self.generate_bookopts(config)
        book_opts = {}
        %i[title short_title authors base_url chapname].each do |opt|
          key = opt.to_s
          book_opts[opt] = config[key] if config.include?(key)
        end
        book_opts[:short_title] ||= book_opts[:title]
        book_opts
      end

      def self.run(opts = nil)
        opts ||= parse_opts
        config = read_config opts[:"config-file"]
        outdir = config["outdir"]
        srcdir = config["srcdir"]
        book_opts = generate_bookopts config
        setup_outdir srcdir, outdir
        generate_webmanifest outdir, book_opts[:title], book_opts[:short_title]
        book = Book.new book_opts
        puts "Writing book to\n  #{outdir}"
        puts
        book.write config["chapters"], config["appendices"], outdir, sitemap: true
        return unless opts[:watch]

        Filewatcher.new("#{srcdir}/*.adoc").watch do |changes|
          chapters = []
          appendices = []
          changes.each_key do |filename|
            puts "Detected change in\n  #{filename}"
            puts
            chapters.append(filename) if config["chapters"].include?(filename)
            appendices.append(filename) if config["appendices"].include?(filename)
          end
          puts "Regenerating book:"
          puts "  Chapters: #{chapters.map { |c| Pathname(c).basename }.join ", "}" unless chapters.empty?
          puts "  Appendices: #{appendices.map { |a| Pathname(a).basename }.join ", "}" unless appendices.empty?
          puts
          book.write chapters, appendices, config["outdir"]
        end
      end
    end
  end
end
