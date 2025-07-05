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
    end
  end
end
