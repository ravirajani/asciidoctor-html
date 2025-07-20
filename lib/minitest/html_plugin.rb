# frozen_string_literal: true

require "pathname"
require "cgi"

# Add class to Minitest module
module Minitest
  # Custom reporter class that creates an HTML file in the docs folder
  class HTMLReporter < AbstractReporter
    DOCS_DIR = "#{__dir__}/../../docs/asciidoc".freeze
    TESTS_DIR = "#{__dir__}/../../test/asciidoctor/html".freeze
    CONFIG_FILE = "#{DOCS_DIR}/config.yml".freeze

    def initialize
      @results = {}
      super
    end

    def record(result)
      @results[result.name] = result.failures
    end

    def display_failure(failure)
      %([source,shell,role="border border-danger"]\n----\n#{failure}\n----\n)
    end

    def display_result_title(name, failed, color)
      status_icon = %(pass:[<i class="bi bi-#{failed ? "x" : "check"}-lg text-#{color}"></i>])
      %(#{status_icon} #{name.tr("_", " ").capitalize})
    end

    def display_result(name, adoc)
      key = "test_#{name}"
      failed = @results[key]&.size&.positive?
      color = failed ? "danger" : "success"
      id = "test-#{name.tr "_", "-"}"
      title = display_result_title name, failed, color
      pre = %([source,asciidoc]\n------\n#{adoc}\n------\n)
      fail = failed ? display_failure(@results[key].join("\n")) : ""
      %([##{id}]\n== #{title}\n\n#{pre}#{fail}\n\n#{adoc}\n\n)
    end

    def report_files(results, dirname)
      dirname.children.sort.each do |filepath|
        next unless filepath.extname == ".adoc"

        results << display_result(filepath.basename.sub_ext("").to_s,
                                  File.read(filepath))
      end
    end

    def report
      time = %([.lead]\n#{Time.now.strftime("%d/%m/%Y %H:%M")}\n)
      results = []
      Pathname(TESTS_DIR).children.reject { |f| f.file? || f.basename.to_s.start_with?("_") }.sort.each do |pn|
        report_files results, pn
      end
      adoc = %(= Test Results\n\n#{time}\n#{results.join "\n"})
      File.write("#{DOCS_DIR}/tests.adoc", adoc)
      Asciidoctor::Html::CLI.run({ "config-file": CONFIG_FILE, watch: false })
    end
  end

  def self.plugin_html_init(_options)
    reporter << HTMLReporter.new
  end
end
