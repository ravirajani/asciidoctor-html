# frozen_string_literal: true

require "date"
require_relative "highlightjs"

module Asciidoctor
  module Html
    ASSETS_PATH = "assets"
    CSS_PATH = "#{ASSETS_PATH}/css".freeze
    IMG_PATH = "#{ASSETS_PATH}/img".freeze

    # The template for the book layout
    module Template
      def self.nav_item(target, text, content = "", active: false)
        active_class = active ? %( class="active") : ""
        link = %(<a href="#{target}">#{text}</a>)
        subnav = content.empty? ? content : "\n#{content}\n"
        %(<li#{active_class}>#{link}#{subnav}</li>\n)
      end

      def self.nav(items = [])
        %(<ul>\n#{items.join "\n"}\n</ul>)
      end

      def self.nav_text(chapnum, chaptitle)
        return chaptitle if chapnum.empty?

        %(<span class="title-mark">#{chapnum}</span>#{chaptitle})
      end

      def self.chaptitle(chapname, numeral, doctitle, num_appendices)
        return doctitle unless num_appendices.positive?

        numeral = num_appendices == 1 ? "" : " #{numeral}"
        %(<span class="title-prefix">#{chapname}#{numeral}</span>#{doctitle})
      end

      def self.chapnum(numeral, num_appendices)
        numeral == "0" || num_appendices.positive? ? "" : numeral
      end

      def self.main(content, nav_items, chapnum, chaptitle)
        %(<main>
          <div class="sidebar">
          <div class="search">
            <button type="button" class="btn btn-outline-secondary">
              <i class="bi bi-search"></i> Search&#8230;
            </button>
          </div> <!-- .search -->
          <nav>\n#{nav nav_items}\n</nav>
          </div> <!-- .sidebar -->
          <div class="content">
          <h2>#{nav_text chapnum, chaptitle}</h2>
          #{content}
          </div> <!-- .content -->
          </main>\n).gsub("\n          ", "\n")
      end

      def self.header(title)
        %(<header>
          <div class="home">
            <a href="">#{title}</a>
          </div>
          <div class="menu">
            <button type="button" class="btn">
              <i class="bi bi-list"></i>
            </button>
          </div>
          </header>\n).gsub("\n          ", "\n")
      end

      def self.footer(author, year)
        %(<footer>&#169; #{year} #{author}</footer>\n)
      end

      def self.highlightjs(langs)
        langs.map do |lang|
          %(<script src="#{Highlightjs::CDN_PATH}/languages/#{lang}.min.js"></script>)
        end.join("\n  ")
      end

      # opts:
      # - title: String
      # - author: String
      # - date: Date
      # - chapnum: Int
      # - chaptitle: String
      # - langs: Array[String]
      def self.html(content, nav_items, opts = {})
        %(<!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>#{opts[:title]}</title>
            <link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png">
            <link rel="icon" type="image/png" sizes="32x32" href="favicon-32x32.png">
            <link rel="icon" type="image/png" sizes="16x16" href="favicon-16x16.png">
            <link rel="manifest" href="site.webmanifest">
            <link rel="stylesheet" href="#{CSS_PATH}/styles.css">
            <link rel="stylesheet" href="#{Highlightjs::CDN_PATH}/styles/default.min.css">
            <script src="#{Highlightjs::CDN_PATH}/build/highlight.min.js"></script>
            #{highlightjs opts[:langs]}
            <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
          </head>
          <body>
          #{header opts[:title]}
          #{main content, nav_items, opts[:chapnum], opts[:chaptitle]}
          #{footer opts[:author], opts[:date].year}
          <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.6/dist/js/bootstrap.bundle.min.js"
                  integrity="sha384-j1CDi7MgGQ12Z7Qab0qlWQ/Qqz24Gc6BM0thvEMVjHnfYGF0rmFCozFSxQBxwHKO"
                  crossorigin="anonymous"></script>
          <script>hljs.highlightAll();</script>
          </body>
          </html>\n).gsub("\n          ", "\n")
      end
    end
  end
end
