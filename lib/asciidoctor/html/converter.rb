# frozen_string_literal: true

require "asciidoctor"
require_relative "olist"
require_relative "utils"

module Asciidoctor
  module Html
    # A custom HTML5 converter that plays nicely with Bootstrap CSS
    class Converter < (Asciidoctor::Converter.for "html5")
      register_for "html5"

      def convert_section(node)
        doc_attrs = node.document.attributes
        level = node.level
        show_sectnum = node.numbered && level <= (doc_attrs["sectnumlevels"] || 1).to_i
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
        unless node.title?
          # Hack to ensure numbering of example block in all circumstances
          node.title = ""
          node.assign_caption nil
        end
        node.set_attr "reftext", Utils.title_prefix(node)
        content = Utils.display_title(node) + node.content
        Utils.wrap_node content, node
      end

      def convert_olist(node)
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
