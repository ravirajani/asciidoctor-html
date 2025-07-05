# frozen_string_literal: true

module Asciidoctor
  module Html
    # The template for the book layout
    module Template
      def self.nav_item(target, text, content = "", active: false)
        active_class = active ? " active" : ""
        link = %(<a class="nav-link#{active_class}" href="#{target}">#{text}</a>)
        subnav = content.empty? ? content : "\n#{content}\n"
        %(<li class="nav-item">#{link}#{subnav}</li>\n)
      end

      def self.nav(items = [])
        %(<ul class="nav">\n#{items.join "\n"}\n</ul> <!-- .nav -->)
      end
    end
  end
end
