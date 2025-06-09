# frozen_string_literal: true

module Asciidoctor
  module Html
    # Utilities shared by multiple elements
    module Utils
      def self.id_class_string(id, classes = nil)
        id_attr = id ? %( id="#{id}") : ""
        class_attr = classes ? %( class="#{classes}") : ""
        "#{id_attr}#{class_attr}"
      end

      def self.short_id_class_string(id, classes)
        result = ""
        result << "##{id}" if id
        result << ".#{classes.tr "\s", "."}" if classes
      end

      def self.display_number(node)
        if node.numeral
          chapter_number = node.document.attr("chapnum")
          chapter_number ? "#{chapter_number}.#{node.numeral}" : node.numeral
        else
          ""
        end
      end

      def self.display_title(node)
        prefix = display_title_prefix node
        node.title? ? %(<h5 class="block-title">#{prefix}<span class="title-content">#{node.title}</span></h5>\n) : ""
      end

      def self.title_prefix(node)
        (node.style ? "#{node.style.capitalize} " : "") + display_number(node)
      end

      def self.display_title_prefix(node)
        prefix = title_prefix node
        prefix.empty? ? "" : %(<span class="title-prefix">#{prefix}</span>)
      end

      def self.wrap_id_classes(content, id, classes, tag_name = :div)
        id_class_string = id_class_string id, classes
        %(<#{tag_name}#{id_class_string}>\n#{content}\n</#{tag_name}> <!-- #{short_id_class_string id, classes} -->\n)
      end

      def self.wrap_node(content, node, tag_name = :div)
        classes = [node.context, node.style, node.role].compact.join " "
        wrap_id_classes content, node.id, classes, tag_name
      end
    end
  end
end
