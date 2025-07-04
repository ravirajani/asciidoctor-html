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

      # Don't include an id if the element will be wrapped
      # by a title, since the wrapper should have the id.
      def self.dyn_id_class_attr_str(node, classes = nil)
        id = node.title? ? nil : node.id
        id_class_attr_str id, classes
      end

      def self.id_class_sel_str(id, classes)
        result = ""
        result += "##{id}" if id
        result + ".#{classes.tr "\s", "."}" if classes
      end

      def self.id_class_sel_comment(id, classes)
        id || (classes && !classes.empty?) ? " <!-- #{id_class_sel_str id, classes} -->" : ""
      end

      def self.show_title?(node)
        node.attr?("showcaption") || node.title?
      end

      def self.display_title(node, needs_prefix: true)
        prefix = needs_prefix ? display_title_prefix(node) : ""
        show_title?(node) ? %(<h6 class="block-title">#{prefix}#{node.title}</h6>\n) : ""
      end

      def self.display_title_prefix(node)
        prefix = node.reftext? ? node.reftext : ""
        node.title? && !node.title.empty? ? %(<span class="title-prefix">#{prefix}</span>) : prefix
      end

      def self.wrap_id_classes(content, id, classes, tag_name = :div)
        id_class = id_class_attr_str id, classes
        %(<#{tag_name}#{id_class}>\n#{content}\n</#{tag_name}>#{id_class_sel_comment id, classes}\n)
      end

      def self.wrap_node(content, node, tag_name = :div)
        base_class = node.context
        mod = node.attr?("env") ? node.attr("env") : node.style
        mod_class = if mod && mod != base_class.to_s
                      "#{base_class}-#{mod}"
                    else
                      ""
                    end
        classes = [base_class, mod_class, node.role].compact.map(&:to_s).uniq.join(" ").strip
        wrap_id_classes content, node.id, classes, tag_name
      end

      def self.wrap_node_with_title(content, node, tag_name = :div, needs_prefix: false)
        show_title?(node) ? wrap_node(display_title(node, needs_prefix:) + content, node, tag_name) : content
      end

      def self.wrap_id_classes_with_title(content, node, id, classes, needs_prefix: false)
        show_title?(node) ? wrap_id_classes(display_title(node, needs_prefix:) + content, id, classes) : content
      end
    end
  end
end
