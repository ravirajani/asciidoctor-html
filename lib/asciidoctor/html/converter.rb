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
        document = node.document
        level = node.level
        Utils.reset_counters(document) if Utils.number_within(document) == :section && level == 1
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
        node.title = "" unless node.title? # Ensures the caption is displayed
        Utils.assign_numeral! node, "thm"
        node.set_attr "reftext", Utils.title_prefix(node)
        Utils.wrap_node_with_title node.content, node, needs_prefix: true
      end

      def convert_image(node)
        return super if node.option?("inline") || node.option?("interactive")

        node.style = "figure"
        Utils.assign_numeral! node, "fig"
        target = node.attr "target"
        width = node.attr?("width") ? %( width="#{node.attr "width"}") : ""
        height = node.attr?("height") ? %( height="#{node.attr "height"}") : ""
        alt = encode_attribute_value node.alt
        image = %(<img src="#{node.image_uri target}" alt="#{alt}"#{width}#{height}#{@void_element_slash}>)
        title = node.title? ? node.title : ""
        caption = %(<figcaption>#{Utils.display_title_prefix node}#{title}</figcaption>)
        content = %(<figure>\n    #{image}\n    #{caption}\n</figure>)
        Utils.wrap_id_classes content, node.id, "figbox"
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
