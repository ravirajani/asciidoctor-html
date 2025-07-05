# frozen_string_literal: true

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
        return chaptitle unless chapnum.positive?

        %(<span class="title-mark">#{chapnum}</span>#{chaptitle})
      end

      def self.main(content, nav_items, chapnum, chaptitle)
        indent = " " * 10
        %(<main>
          <nav class="sidebar">
          #{nav nav_items}
          </nav>
          <div class="content">
          <h2>#{nav_text chapnum, chaptitle}</h2>
          #{content}
          </div>
          </main>\n).gsub("\n#{indent}", "\n")
      end
    end
  end
end
