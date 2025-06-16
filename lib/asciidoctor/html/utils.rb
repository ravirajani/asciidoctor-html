# frozen_string_literal: true

module Asciidoctor
  module Html
    # Utilities shared by multiple elements
    module Utils
      def self.id_class_attr_str(id, classes = nil)
        id_attr = id ? %( id="#{id}") : ""
        class_attr = classes ? %( class="#{classes}") : ""
        "#{id_attr}#{class_attr}"
      end

      def self.id_class_sel_str(id, classes)
        result = ""
        result += "##{id}" if id
        result + ".#{classes.tr "\s", "."}" if classes
      end

      def self.sectnum(node)
        parent = node
        sectnum = nil
        if node.document.attr? "sectnums"
          parent = parent.parent until parent.instance_of?(Asciidoctor::Section) || !parent.parent
          sectnum = parent.numeral
        end
        sectnum
      end

      def self.display_number(node)
        if node.numeral
          prefix_number = node.document.attr("chapnum") || sectnum(node)
          prefix_number ? "#{prefix_number}.#{node.numeral}" : node.numeral.to_s
        else
          ""
        end
      end

      def self.display_title(node)
        prefix = display_title_prefix node
        node.title? ? %(<h5 class="block-title">#{prefix}#{node.title}</h5>\n) : ""
      end

      def self.title_prefix(node)
        name = node.style
        (name ? "#{name.capitalize} " : "") + display_number(node)
      end

      def self.display_title_prefix(node)
        prefix = title_prefix node
        display_prefix = node.title? && !node.title.empty? ? %(<span class="title-prefix">#{prefix}</span>) : prefix
        prefix.empty? ? "" : display_prefix
      end

      def self.wrap_id_classes(content, id, classes, tag_name = :div)
        id_class = id_class_attr_str id, classes
        %(<#{tag_name}#{id_class}>\n#{content}\n</#{tag_name}> <!-- #{id_class_sel_str id, classes} -->\n)
      end

      def self.wrap_node(content, node, tag_name = :div)
        base_class = node.context
        mod_class = node.style && node.style != node.context.to_s ? "#{base_class}-#{node.style}" : ""
        classes = [base_class, mod_class, node.role].compact.map(&:to_s).uniq.join(" ").strip
        wrap_id_classes content, node.id, classes, tag_name
      end
    end
  end
end
