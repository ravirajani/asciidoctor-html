# frozen_string_literal: true

require "asciidoctor"
require_relative "olist"
require_relative "utils"
require_relative "figure"

module Asciidoctor
  module Html
    # A custom HTML5 converter that plays nicely with Bootstrap CSS
    class Converter < (Asciidoctor::Converter.for "html5")
      register_for "html5"

      include Figure

      def convert_section(node)
        document = node.document
        level = node.level
        show_sectnum = node.numbered && level <= (document.attr("sectnumlevels") || 1).to_i
        tag_name = %(h#{[level + 2, 6].min})
        sectnum = show_sectnum ? %(<span class="title-mark">#{node.sectnum ""}</span>) : ""
        content = %(<#{tag_name}>#{sectnum}#{node.title}) +
                  %(</#{tag_name}>\n#{node.content})
        Utils.wrap_node content, node, :section
      end

      def convert_paragraph(node)
        content = %(<p>#{node.content}</p>\n)
        Utils.wrap_node_with_title content, node
      end

      def convert_example(node)
        p node.context unless Utils.show_title?(node)
        Utils.wrap_node_with_title node.content, node, needs_prefix: true
      end

      def convert_image(node)
        return super if node.option?("inline") || node.option?("interactive")

        content = display_figure node
        Utils.wrap_id_classes content, node.id, ["figbox", node.role].compact.join(" ")
      end

      def convert_inline_image(node)
        return super if node.option?("inline") || node.option?("interactive")

        target = node.target
        mark = node.parent.attr("figcap-mark")
        attrs = image_attrs node
        image = display_image node, target, attrs
        title = node.attr?("title") ? node.attr("title") : ""
        caption = mark ? %(<span class="li-mark">#{mark}</span>#{title}) : title
        %(    #{image}\n    <figcaption>#{caption}</figcaption>)
      end

      def convert_olist(node)
        return convert_figlist(node) if node.style == Olist::FIGLIST_STYLE

        depth = Olist.depth node
        level = depth + 1
        parent = Olist.parent_with_offset node
        classes = ["olist level-#{level}", parent ? Olist::FLAT_STYLE : node.style, node.role].compact.join(" ")
        result = [%(<ol#{Utils.dyn_id_class_attr_str node, classes}>)]
        node.items.each_with_index do |item, idx|
          result << Olist.convert_list_item(node, parent, depth, item, idx)
        end
        result << %(</ol> <!-- .level-#{level} -->\n)
        Utils.wrap_id_classes_with_title result.join("\n"), node, node.id, "list-wrapper"
      end
    end
  end
end
