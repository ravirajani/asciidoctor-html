# frozen_string_literal: true

require "date"
require_relative "highlightjs"
require_relative "popovers"

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

      def self.nav_text(chapnum, chaptitle)
        return chaptitle if chapnum.empty?

        %(<span class="title-mark">#{chapnum}</span>#{chaptitle})
      end

      def self.appendix_title(chapname, numeral, doctitle, num_appendices)
        numeral = num_appendices == 1 ? "" : " #{numeral}"
        %(<span class="title-prefix">#{chapname}#{numeral}</span>#{doctitle})
      end

      def self.sidebar(nav_items)
        <<~HTML
          <div id="sidebar" class="sidebar collapse collapse-horizontal">
          <nav id="sidenav"><ul>
          #{nav_items.join "\n"}
          </ul></nav>
          </div> <!-- .sidebar -->
        HTML
      end

      def self.main(content, chapnum, chaptitle, author, year)
        <<~HTML
          <main class="main">
          <div class="content-container">
          <h1>#{nav_text chapnum, chaptitle}</h1>
          #{content}
          #{footer author, year}
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

      def self.header(title, short_title, nav: true)
        nav_btn = if nav
                    <<~HTML
                      <button type="button" class="btn menu"
                              data-bs-toggle="collapse" data-bs-target="#sidebar"
                              aria-expanded="false" aria-controls="sidebar">
                        <i class="bi bi-list"></i>
                      </button>
                    HTML
                  else
                    ""
                  end
        <<~HTML
          <header class="header">
            <a class="home d-none d-sm-block" href="./">#{title}</a>
            <a class="home d-block d-sm-none" href="./">#{short_title}</a>
            #{nav_btn}
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

      def self.head(title, langs)
        <<~HTML
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
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
      # - date: Date
      # - chapnum: Int
      # - chaptitle: String
      # - langs: Array[String]
      def self.html(content, nav_items, opts = {})
        nav = (nav_items.size > 1)
        hash_listener = if nav
                          <<~JS
                            addEventListener('hashchange', function() {
                              collapse = bootstrap.Collapse.getInstance('#sidebar');
                              if(collapse) collapse.hide();
                            });
                          JS
                        else
                          ""
                        end
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          #{head opts[:title], opts[:langs]}
          <body>
          #{header opts[:title], opts[:short_title], nav:}
          #{sidebar(nav_items) if nav}
          #{main content, opts[:chapnum], opts[:chaptitle], opts[:author], opts[:date].year}
          <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.6/dist/js/bootstrap.bundle.min.js"
                  integrity="sha384-j1CDi7MgGQ12Z7Qab0qlWQ/Qqz24Gc6BM0thvEMVjHnfYGF0rmFCozFSxQBxwHKO"
                  crossorigin="anonymous"></script>
          <script>
          const touch = matchMedia('(hover: none)').matches;
          #{Highlightjs::PLUGIN}
          hljs.highlightAll();
          #{hash_listener}
          #{Popovers::POPOVERS}
          </script>
          </body>
          </html>
        HTML
      end
    end
  end
end
