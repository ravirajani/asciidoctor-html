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

    def display_result_title(name, id, failed, color)
      style = %(style="vertical-align: -0.125em;")
      status_icon = %(<i class="bi bi-#{failed ? "x" : "check"}-square text-#{color}" #{style}></i>)
      chevron = %(<i class="bi bi-chevron-expand"></i>)
      attrs = %(type="button" data-bs-toggle="collapse" data-bs-target="##{id}")
      %(#{status_icon}<button #{attrs} class="btn btn-link">#{chevron} #{name.tr("_", " ").capitalize}</button>\n)
    end

    def display_result(name, adoc, html)
      key = "test_#{name}"
      failed = @results[key]&.size&.positive?
      color = failed ? "danger" : "success"
      id = "test-#{name.tr "_", "-"}"
      title = display_result_title name, id, failed, color
      pre = %(<pre><code class="language-asciidoc">#{CGI.escapeHTML adoc}</code></pre>\n)
      fail = failed ? display_failure(CGI.escapeHTML(@results[key].join("\n")), color) : ""
      %(<div>#{title}<div class="collapse full-width-bg" id="#{id}">#{pre}#{fail}#{html}</div></div>)
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
      html = %(#{frontmatter}#{time}#{results.join "\n"})
      File.write("#{DOCS_DIR}/index.html", html)
    end
  end

  def self.plugin_html_init(_options)
    reporter << HTMLReporter.new
  end
end
