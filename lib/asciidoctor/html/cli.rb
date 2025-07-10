# frozen_string_literal: true

require "optparse"

module Asciidoctor
  module Html
    # The command line interface
    module CLI
      DEFAULT_OPTIONS = {
        outdir: "www",
        "config-file": "config.yml",
        srcdir: ".",
        watch: false
      }.freeze

      def self.parse_opts
        options = DEFAULT_OPTIONS.dup
        OptionParser.new do |parser|
          parser.on("-w", "--watch",
                    "Watch for file changes in SRCDIR. Default: unset")
          parser.on("-o", "--outdir OUTDIR",
                    "Where to build the HTML files. Default: #{options[:outdir]}")
          parser.on("-s", "--srcdir SRCDIR",
                    "Where to read the Asciidoc files. Default: #{options[:srcdir]}")
          parser.on("-c", "--config-file CONFIG",
                    "Location of config file. Default: #{options[:"config-file"]}")
        end.parse!(into: options)
        options
      end

      def self.run
        options = parse_opts
        p options
      end
    end
  end
end
