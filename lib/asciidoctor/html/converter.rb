# frozen_string_literal: true

require "asciidoctor"
require_relative "list"
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
        content = %(<#{tag_name}>#{sectnum}#{node.title}</#{tag_name}>\n#{node.content})
        Utils.wrap_node content, node, :section
      end

      def convert_paragraph(node)
        content = %(<p#{Utils.dyn_id_class_attr_str node, node.role}>#{node.content}</p>\n)
        Utils.wrap_node_with_title content, node
      end

      def convert_admonition(node)
        name = node.attr "name"
        icon_class = case name
                     when "note" then "pencil-fill"
                     when "tip" then "info-lg"
                     else "exclamation-lg"
                     end
        icon = %(<div class="icon"><i class="bi bi-#{icon_class}"></i></div>)
        content = %(#{icon}\n#{Utils.display_title node, needs_prefix: false}#{node.content})
        Utils.wrap_id_classes content, node.id, "admonition admonition-#{name}"
      end

      def convert_stem(node)
        open, close = BLOCK_MATH_DELIMITERS[node.style.to_sym]
        equation = node.content || ""
        equation = "#{open}#{equation}#{close}" unless (equation.start_with? open) && (equation.end_with? close)
        classes = ["stem"]
        if node.option? "numbered"
          equation = %(<div class="equation">\n#{equation}\n</div> <!-- .equation -->)
          equation = %(#{equation}\n<div class="equation-number">#{node.reftext}</div>)
          classes << "stem-equation"
        end
        content = %(<div#{Utils.dyn_id_class_attr_str node, classes.join(" ")}>\n#{equation}\n</div>\n)
        Utils.wrap_id_classes_with_title content, node, node.id, "stem-wrapper"
      end

      def convert_inline_callout(node)
        i = node.text.to_i
        case i
        when 1..20
          (i + 9311).chr(Encoding::UTF_8)
        when 21..50
          (i + 3230).chr(Encoding::UTF_8)
        else
          "[#{node.text}]"
        end
      end

      def convert_listing(node)
        nowrap = (node.option? "nowrap") || !(node.document.attr? "prewrap")
        if node.style == "source"
          lang = node.attr "language"
          code_open = %(<code#{%( class="language-#{lang}") if lang}>)
          pre_open = %(<pre#{%( class="nowrap") if nowrap}>#{code_open})
          pre_close = "</code></pre>"
        else
          pre_open = %(<pre#{%( class="nowrap") if nowrap}>)
          pre_close = "</pre>"
        end
        needs_prefix = node.option? "numbered"
        title = Utils.display_title(node, needs_prefix:)
        content = title + pre_open + node.content + pre_close
        Utils.wrap_node content, node
      end

      def convert_open(node)
        collapsible = node.option? "collapsible"
        title = if collapsible
                  %(<summary>#{node.title || "Details"}</summary>\n)
                else
                  Utils.display_title(node, needs_prefix: false)
                end
        tag_name = collapsible ? :details : :div
        Utils.wrap_node(title + node.content, node, tag_name)
      end

      def convert_example(node)
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
        mark = node.parent.attr "mark"
        title_attr = node.attr? "title"
        if mark # The image is part of a figlist
          title = title_attr ? node.attr("title") : ""
          %(    #{display_image node, target}
          <figcaption><span class="li-mark">#{mark}</span>#{title}</figcaption>).gsub(/^      /, "")
        else
          display_image node, target, title_attr:
        end
      end

      def convert_olist(node)
        return convert_figlist(node) if node.style == "figlist"

        List.convert node
      end

      def convert_colist(node)
        node.style = "arabic-circled"
        List.convert node
      end

      def convert_ulist(node)
        List.convert node, :ul
      end

      def convert_dlist(node)
        classes = ["dlist", node.style, node.role].compact.join(" ")
        result = [%(<dl#{Utils.dyn_id_class_attr_str node, classes}>)]
        node.items.each do |terms, dd|
          terms.each do |dt|
            result << %(<dt>#{dt.text}</dt>)
          end
          next unless dd

          result << "<dd>"
          result << %(<p>#{dd.text}</p>) if dd.text?
          result << dd.content if dd.blocks?
          result << "</dd>"
        end
        result << "</dl>\n"
        Utils.wrap_id_classes_with_title result.join("\n"), node, node.id, "dlist-wrapper"
      end

      def convert_inline_anchor(node)
        if node.type == :xref && !node.text
          target = node.document.catalog[:refs][node.attr("refid")]
          if target.inline? && (text = target.text)&.match?(/\A<i class="bi/)
            return %(<a href="#{node.target}">#{text}</a>)
          end
        end
        super
      end
    end
  end
end
