# frozen_string_literal: true

require "date"
require_relative "highlightjs"

module Asciidoctor
  module Html
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

      def self.appendix_title(chapname, numeral, doctitle, num_appendices)
        numeral = num_appendices == 1 ? "" : " #{numeral}"
        %(<span class="title-prefix">#{chapname}#{numeral}</span>#{doctitle})
      end

      def self.sidebar(nav_items)
        %(<div id="sidebar" class="sidebar collapse collapse-horizontal">
          <div class="search">
            <button type="button" class="btn">
              <i class="bi bi-search"></i> Search&#8230;
            </button>
          </div> <!-- .search -->
          <nav>\n#{nav nav_items}\n</nav>
          </div>).gsub("\n          ", "\n")
      end

      def self.main(content, chapnum, chaptitle, author, year)
        %(<main class="main">
          <div class="content-container">
          <h2>#{nav_text chapnum, chaptitle}</h2>
          #{content}
          </div>
          #{footer author, year}
          </main>\n).gsub("\n          ", "\n")
      end

      def self.header(title)
        %(<header class="header">
            <a class="home" href="./">#{title}</a>
            <button type="button" class="btn menu" data-bs-toggle="collapse" data-bs-target="#sidebar"
                    aria-expanded="false" aria-controls="sidebar">
              <i class="bi bi-list"></i>
            </button>
          </header>\n).gsub("\n          ", "\n")
      end

      def self.footer(author, year)
        %(<footer class="footer">&#169; #{year} #{author}</footer>\n)
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
            <link rel="apple-touch-icon" sizes="180x180" href="#{FAVICON_PATH}/apple-touch-icon.png">
            <link rel="icon" type="image/png" sizes="32x32" href="#{FAVICON_PATH}/favicon-32x32.png">
            <link rel="icon" type="image/png" sizes="16x16" href="#{FAVICON_PATH}/favicon-16x16.png">
            <link rel="manifest" href="#{FAVICON_PATH}/site.webmanifest">
            <link rel="stylesheet" href="#{CSS_PATH}/styles.css">
            <link rel="stylesheet" href="#{Highlightjs::CDN_PATH}/styles/default.min.css">
            <script src="#{Highlightjs::CDN_PATH}/highlight.min.js"></script>
            #{highlightjs opts[:langs]}
            <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
          </head>
          <body>
          #{header opts[:title]}
          #{sidebar nav_items}
          #{main content, opts[:chapnum], opts[:chaptitle], opts[:author], opts[:date].year}
          <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.6/dist/js/bootstrap.bundle.min.js"
                  integrity="sha384-j1CDi7MgGQ12Z7Qab0qlWQ/Qqz24Gc6BM0thvEMVjHnfYGF0rmFCozFSxQBxwHKO"
                  crossorigin="anonymous"></script>
          <script>
            hljs.highlightAll();
            addEventListener("hashchange", function(){
              collapse = bootstrap.Collapse.getInstance("#sidebar");
              if(collapse) collapse.hide();
            })
          </script>
          </body>
          </html>\n).gsub("\n          ", "\n")
      end
    end
  end
end
