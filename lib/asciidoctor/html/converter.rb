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

      def convert_preamble(node)
        %(<div class="preamble">\n#{node.content}</div> <!-- .preamble -->\n)
      end

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
        content = %(<p#{Utils.dyn_id_class_attr_str node, node.role}>#{node.content}</p>\n)
        Utils.wrap_node_with_title content, node
      end

      def convert_stem(node)
        open, close = BLOCK_MATH_DELIMITERS[node.style.to_sym]
        equation = node.content || ""
        equation = "#{open}#{equation}#{close}" unless (equation.start_with? open) && (equation.end_with? close)
        Utils.wrap_node equation, node
      end

      def convert_listing(node)
        nowrap = (node.option? "nowrap") || !(node.document.attr? "prewrap")
        if node.style == "source"
          lang = node.attr "language"
          code_open = %(<code#{%( class="language-#{lang}") if lang}>)
          pre_open = %(<div class="pre-wrapper">\n<pre#{%( class="nowrap") if nowrap}>#{code_open})
          pre_close = "</code></pre>\n</div> <!-- .pre-wrapper -->"
        else
          pre_open = %(<div class="pre-wrapper">\n<pre#{%( class="nowrap") if nowrap}>)
          pre_close = "</pre>\n</div> <!-- .pre-wrapper -->"
        end
        content = Utils.display_title(node, needs_prefix: false) + pre_open + node.content + pre_close
        Utils.wrap_node content, node
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
        mark = node.parent.attr("mark")
        if mark # The image is part of a figlist
          title = node.attr?("title") ? node.attr("title") : ""
          %(    #{display_image node, target}
          <figcaption><span class="li-mark">#{mark}</span>#{title}</figcaption>).gsub(/^      /, "")
        else
          display_image node, target, title_attr:
        end
      end

      def convert_olist(node)
        return convert_figlist(node) if node.style == "figlist"

        depth = node.attr "list-depth"
        flat = node.attr? "flat-style"
        level = depth + 1
        classes = ["olist level-#{level}", flat ? "pseudocode" : node.style, node.role].compact.join(" ")
        result = [%(<ol#{Utils.dyn_id_class_attr_str node, classes}>)]
        node.items.each do |item|
          result << Olist.display_list_item(item)
        end
        result << %(</ol> <!-- .level-#{level} -->\n)
        Utils.wrap_id_classes_with_title result.join("\n"), node, node.id, "list-wrapper"
      end
    end
  end
end
