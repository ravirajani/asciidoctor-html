# frozen_string_literal: true

require_relative "highlightjs"
require_relative "popovers"
require_relative "sidebar"
require_relative "scroll"
require_relative "flip"

module Asciidoctor
  module Html
    # The template for the book layout
    module BookTemplate
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

        %(<div class="nav-mark">#{chapprefix}</div>#{chaptitle})
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

      def self.toggle_button(pagestyle)
        states = {
          single: "single page view",
          multi: "multipage view",
          presentation: "presentation view (ESC to exit)"
        }
        alternate_states = states.map do |key, value|
          <<~HTML
            <li>
            <a class="dropdown-item#{" active" if pagestyle == key}" href="#page" data-viewmode="#{key}">#{value}</a>
            </li>
          HTML
        end
        <<~HTML
          <div class="layout-toggle">
            <div class="dropdown">
              <button class="btn btn-link dropdown-toggle" id="btn-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                #{states[pagestyle]}
              </button>
              <ul id="viewmode-actions" class="dropdown-menu">
                #{alternate_states.join "\n"}
              </ul>
            </div>
          </div>
        HTML
      end

      def self.chapheader(chapheading, chapsubheading)
        chapheading_suffix = ": " if chapheading
        <<~HTML
          <div class="breadcrumb">
            <a href="#page" class="link-offset-2 link-underline-opacity-50 link-underline-opacity-100-hover">
              #{chapheading}#{chapheading_suffix}#{chapsubheading}
            </a>
          </div>
        HTML
      end

      def self.chapheading(text)
        %(<h1 class="chapheading">#{text}</h1>) if text
      end

      # opts:
      # - chapheading: String
      # - chapsubheading: String
      # - content: String
      # - has_subnav: Boolean
      # - authors: String
      # - date: Date
      # - pagestyle: Symbol
      def self.main(opts)
        <<~HTML
          <main id="main" class="main">
          <div id="content-container" class="content-container dynamic-width">
          #{chapheader opts[:chapheading], opts[:chapsubheading]}
          <div class="chaphead d-block">
            #{toggle_button opts[:pagestyle] if opts[:has_subnav]}
            #{chapheading opts[:chapheading]}
            <h1 class="chaptitle">#{opts[:chapsubheading]}</h1>
          </div>
          #{opts[:content]}
          #{footer opts[:authors]}
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

      def self.header(title, short_title, chapheading, has_subnav)
        sublink = <<~HTML
          <span id="header-chapheading" class="home-sublink"><a class="home" href="#page">#{chapheading}</a></span>
        HTML
        <<~HTML
          <header class="header#{" with-margin" unless has_subnav}">
            <div class="dynamic-width">
              <div class="home-container">
                <a class="home d-none d-sm-block" href="./">#{title}</a>
                <a class="home d-block d-sm-none" href="./">#{short_title}</a>
                #{sublink if chapheading}
              </div>
            </div>
          </header>
        HTML
      end

      def self.footer(authors)
        <<~HTML
          <footer class="footer">
            <div class="footer-left">&#169; <span id="cr-year"></span> #{authors}</div>
            <div class="footer-right">Built with
              <a href="https://github.com/ravirajani/asciidoctor-html">asciidoctor-html</a>
            </div>
          </footer>
        HTML
      end

      def self.highlightjs(langs)
        langs.map do |lang|
          %(<script defer src="#{Highlightjs::CDN_PATH}/languages/#{lang}.min.js"></script>)
        end.join("\n  ")
      end

      def self.head(title, description, authors, langs)
        <<~HTML
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          #{%(<meta name="description" content="#{description}">) if description}
          #{%(<meta name="author" content="#{authors}">) if authors}
          <title>#{title}</title>
          <link rel="apple-touch-icon" sizes="180x180" href="#{FAVICON_PATH}/apple-touch-icon.png">
          <link rel="icon" type="image/png" sizes="32x32" href="#{FAVICON_PATH}/favicon-32x32.png">
          <link rel="icon" type="image/png" sizes="16x16" href="#{FAVICON_PATH}/favicon-16x16.png">
          <link rel="manifest" href="#{FAVICON_PATH}/site.webmanifest" crossorigin="anonymous">
          <link rel="stylesheet" href="#{CSS_PATH}/styles.css">
          <link rel="stylesheet" href="#{Highlightjs::CDN_PATH}/styles/tomorrow-night-blue.min.css">
          <script defer src="#{Highlightjs::CDN_PATH}/highlight.min.js"></script>
          #{highlightjs langs}
          <script>
            MathJax = {
              tex: {
                inlineMath: {'[+]': [['$', '$']]}
              },
              output: {
                displayOverflow: 'linebreak'
              }
            };
            ADHT = {}; // Custom namespace.
          </script>
          <script defer src="https://cdn.jsdelivr.net/npm/mathjax@4/tex-chtml.js"></script>
          <script defer src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.6/dist/js/bootstrap.bundle.min.js"
                integrity="sha384-j1CDi7MgGQ12Z7Qab0qlWQ/Qqz24Gc6BM0thvEMVjHnfYGF0rmFCozFSxQBxwHKO"
                crossorigin="anonymous"></script>
        HTML
      end

      # opts:
      # - has_subnav: Boolean
      # - title: String
      # - short_title: String
      # - authors: String
      # - description: String
      # - chapheading: String
      # - chapsubheading: String
      # - langs: Array[String]
      # - at_head_end: String
      # - at_body_end: String
      # - pagestyle: Symbol(single|multi|presentation)
      def self.html(content, nav_items, opts = {})
        nav = !nav_items.empty? && (nav_items.size > 1 || opts[:has_subnav])
        page_classes = ["page"]
        page_classes << "multi" unless opts[:pagestyle] == :single
        page_classes << "presentation" if opts[:pagestyle] == :presentation
        page_classname = page_classes.join " "
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
          #{head opts[:title], opts[:description], opts[:authors], opts[:langs]}
          #{opts[:at_head_end]}
          </head>
          <body>
          #{sidebar(nav_items) if nav}
          <div id="page" class="#{page_classname}">
          #{MENU_BTN if nav}
          #{header opts[:title], opts[:short_title], opts[:chapheading], opts[:has_subnav]}
          #{main content:, **opts}
          </div> <!-- .page -->
          <script>document.getElementById("cr-year").textContent = (new Date()).getFullYear();</script>
          <script type="module">
          #{Highlightjs::PLUGIN}
          #{Popovers::POPOVERS}
          #{Sidebar::TOGGLE if nav}
          #{Scroll::SCROLL}
          #{Flip::FLIP}
          </script>
          #{opts[:at_body_end]}
          </body>
          </html>
        HTML
      end
    end
  end
end
