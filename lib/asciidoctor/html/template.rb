# frozen_string_literal: true

require "date"
require_relative "highlightjs"
require_relative "popovers"
require_relative "sidebar"
require_relative "scroll"

module Asciidoctor
  module Html
    # The template for the book layout
    module Template
      MENU_BTN = <<~HTML
        <button type="button" id="menu-btn" class="btn menu"
                aria-expanded="false" aria-controls="sidebar">
          <i class="bi bi-list"></i>
        </button>
      HTML

      def self.nav_item(target, text, content = "", active: false)
        active_class = active ? %( class="active") : ""
        link = %(<a href="#{target}">#{text}</a>)
        subnav = content.empty? ? content : "\n#{content}\n"
        %(<li#{active_class}>#{link}#{subnav}</li>\n)
      end

      def self.nav_text(chapprefix, chaptitle)
        return chaptitle if chapprefix.empty?

        %(<span class="title-mark">#{chapprefix}</span>#{chaptitle})
      end

      def self.appendix_title(chapname, numeral, doctitle, num_appendices)
        numeral = num_appendices == 1 ? "" : " #{numeral}"
        %(<span class="title-prefix">#{chapname}#{numeral}</span>#{doctitle})
      end

      def self.sidebar(nav_items)
        <<~HTML
          <div id="sidebar" class="sidebar">
          <button id="sidebar-dismiss-btn" class="btn dismiss"><i class="bi bi-x-lg"></i></button>
          <nav><ul>
          #{nav_items.join "\n"}
          </ul></nav>
          </div> <!-- .sidebar -->
        HTML
      end

      # opts:
      # - chapheading: String
      # - chapsubheading: String
      # - content: String
      # - author: String
      # - date: Date
      def self.main(opts)
        <<~HTML
          <main id="main" class="main">
          <div id="content-container" class="content-container">
          #{%(<h1 class="chapheading">#{opts[:chapheading]}</h1>) if opts[:chapheading]}
          <h1 class="chaptitle">#{opts[:chapsubheading]}</h1>
          #{opts[:content]}
          #{footer opts[:author], opts[:date].year}
          </div>
          </main>
        HTML
      end

      def self.sitemap(entries)
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">

          #{entries.join "\n"}
          </urlset>
        XML
      end

      def self.sitemap_entry(url)
        <<~XML
          <url>
            <loc>#{url}</loc>
          </url>
        XML
      end

      def self.header(title, short_title)
        <<~HTML
          <header class="header">
            <a class="home d-none d-sm-block" href="./">#{title}</a>
            <a class="home d-block d-sm-none" href="./">#{short_title}</a>
          </header>
        HTML
      end

      def self.footer(author, year)
        <<~HTML
          <footer class="footer">
            <div class="footer-left">&#169; #{year} #{author}</div>
            <div class="footer-right">Built with
              <a href="https://github.com/ravirajani/asciidoctor-html">asciidoctor-html</a>
            </div>
          </footer>
        HTML
      end

      def self.highlightjs(langs)
        langs.map do |lang|
          %(<script src="#{Highlightjs::CDN_PATH}/languages/#{lang}.min.js"></script>)
        end.join("\n  ")
      end

      def self.head(title, description, author, langs)
        <<~HTML
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            #{%(<meta name="description" content="#{description}">) if description}
            #{%(<meta name="author" content="#{author}">) if author}
            <title>#{title}</title>
            <link rel="apple-touch-icon" sizes="180x180" href="#{FAVICON_PATH}/apple-touch-icon.png">
            <link rel="icon" type="image/png" sizes="32x32" href="#{FAVICON_PATH}/favicon-32x32.png">
            <link rel="icon" type="image/png" sizes="16x16" href="#{FAVICON_PATH}/favicon-16x16.png">
            <link rel="manifest" href="#{FAVICON_PATH}/site.webmanifest">
            <link rel="stylesheet" href="#{CSS_PATH}/styles.css">
            <link rel="stylesheet" href="#{Highlightjs::CDN_PATH}/styles/tomorrow-night-blue.min.css">
            <script src="#{Highlightjs::CDN_PATH}/highlight.min.js"></script>
            #{highlightjs langs}
            <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
          </head>
        HTML
      end

      # opts:
      # - title: String
      # - short_title: String
      # - author: String
      # - description: String
      # - date: Date
      # - chapheading: String
      # - chaptitle: String
      # - langs: Array[String]
      def self.html(content, nav_items, opts = {})
        nav = (nav_items.size > 1)
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          #{head opts[:title], opts[:description], opts[:author], opts[:langs]}
          <body>
          #{sidebar(nav_items) if nav}
          <div id="page" class="page">
          #{MENU_BTN if nav}
          #{header opts[:title], opts[:short_title]}
          #{main content:, **opts}
          </div> <!-- .page -->
          <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.6/dist/js/bootstrap.bundle.min.js"
                  integrity="sha384-j1CDi7MgGQ12Z7Qab0qlWQ/Qqz24Gc6BM0thvEMVjHnfYGF0rmFCozFSxQBxwHKO"
                  crossorigin="anonymous"></script>
          <script>
          #{Highlightjs::PLUGIN}
          hljs.highlightAll();
          #{Popovers::POPOVERS}
          #{Sidebar::TOGGLE if nav}
          #{Scroll::SCROLL}
          </script>
          </body>
          </html>
        HTML
      end
    end
  end
end
