# frozen_string_literal: true

require "pathname"
require "cgi"

# Add class to Minitest module
module Minitest
  # Custom reporter class that creates an HTML file in the docs folder
  class HTMLReporter < AbstractReporter
    DOCS_DIR = "#{__dir__}/../../docs".freeze
    TESTS_DIR = "#{__dir__}/../../test/asciidoctor/html".freeze

    def initialize
      @results = {}
      super
    end

    def record(result)
      @results[result.name] = result.failures
    end

    def display_failure(failure, color)
      %(<pre class="border border-#{color}"><code class="language-shell">#{failure}</code></pre>\n)
    end

    def display_result(name, adoc, html)
      key = "test_#{name}"
      failed = @results[key].size.positive?
      color = failed ? "danger" : "success"
      id = "test-#{name.tr "_", "-"}"
      attrs = %(type="button" data-bs-toggle="collapse" data-bs-target="##{id}")
      title = %(<button #{attrs} class="btn btn-#{color}">#{name.tr("_", " ").capitalize}</button>\n)
      pre = %(<pre><code class="language-asciidoc">#{CGI.escapeHTML adoc}</code></pre>\n)
      fail = failed ? display_failure(CGI.escapeHTML(@results[key].join("\n")), color) : ""
      %(#{title}<div class="collapse" id="#{id}">#{pre}#{fail}#{html}</div>)
    end

    def report_files(results, dirname)
      dirname.children.sort.each do |filepath|
        next unless filepath.extname == ".adoc"

        results << display_result(filepath.basename.sub_ext("").to_s,
                                  File.read(filepath), File.read(filepath.sub_ext(".html")))
      end
    end

    def report
      frontmatter = %(---\nlayout: default\ntitle: Test Results\n---\n)
      time = %(<p class="lead">#{Time.now.strftime("%d/%m/%Y %H:%M")}</p>\n)
      results = []
      Pathname(TESTS_DIR).children.sort.each do |pn|
        next unless pn.directory?

        report_files results, pn
      end
      html = %(#{frontmatter}#{time}<div class="d-grid gap-2">#{results.join "\n"}</div>)
      File.write("#{DOCS_DIR}/index.html", html)
    end
  end

  def self.plugin_html_init(_options)
    reporter << HTMLReporter.new
  end
end
