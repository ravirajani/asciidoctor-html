# frozen_string_literal: true

require "asciidoctor"
require_relative "list"
require_relative "utils"
require_relative "figure"
require_relative "table"

module Asciidoctor
  module Html
    # A custom HTML5 converter that plays nicely with Bootstrap CSS
    class Converter < (Asciidoctor::Converter.for "html5")
      register_for "html5"

      include Figure

      def convert_embedded(node)
        result = [node.content]
        if node.footnotes?
          result << %(<div class="footnotes">)
          node.footnotes.each do |fn|
            result << %(<div class="footnote" id="_footnotedef_#{fn.index}">#{fn.text}</div>)
          end
          result << %(</div>)
        end
        result.join("\n")
      end

      def convert_preamble(node)
        %(<div class="preamble">\n#{node.content}</div> <!-- .preamble -->\n)
      end

      def convert_section(node)
        document = node.document
        level = node.level
        show_sectnum = node.numbered && level <= (document.attr("sectnumlevels") || 1).to_i
        tag_level = [level == 1 ? level + 1 : level + 2, 6].min
        tag_name = %(h#{tag_level})
        sectnum = show_sectnum ? %(<span class="title-mark">#{node.sectnum ""}</span>) : ""
        content = %(<#{tag_name}>#{sectnum}#{node.title}</#{tag_name}>\n#{node.content})
        Utils.wrap_node content, node, :section
      end

      def convert_paragraph(node)
        content = %(<p#{Utils.dyn_id_class_attr_str node, node.role}>#{node.content}</p>\n)
        Utils.wrap_node_with_title content, node
      end

      def convert_quote(node)
        attribution = node.attr?("attribution") ? node.attr("attribution") : nil
        citetitle = node.attr?("citetitle") ? node.attr("citetitle") : nil
        classes = ["blockquote", node.role].compact.join(" ")
        cite_element = citetitle ? %(<cite>#{citetitle}</cite>) : ""
        attr_element = attribution ? %(<span class="attribution">#{attribution}</span>) : ""
        content = %(<blockquote#{Utils.dyn_id_class_attr_str node, classes}>\n#{node.content}\n</blockquote>)
        if attribution || citetitle
          caption = %(<figcaption class="blockquote-footer">\n#{attr_element}#{cite_element}\n</figcaption>)
          content = %(<figure>\n#{content}\n#{caption}\n</figure>\n)
        end
        Utils.wrap_node_with_title content, node
      end

      def convert_admonition(node)
        name = node.attr "name"
        icon_class = case name
                     when "note" then "info-lg"
                     when "tip" then "lightbulb"
                     else "exclamation-lg"
                     end
        icon = %(<div class="icon"><i class="bi bi-#{icon_class}"></i></div>)
        content = node.blocks? ? node.content : "<p>#{node.content}</p>"
        content = %(#{icon}\n#{Utils.display_title node}#{content})
        Utils.wrap_id_classes content, node.id, "admonition admonition-#{name}"
      end

      def convert_sidebar(node)
        classes = ["aside", node.role].compact.join(" ")
        title = node.title? ? %(<h5 class="aside-title">#{node.title}</h5>\n) : ""
        content = "#{title}#{node.content}"
        %(<aside#{Utils.id_class_attr_str node.id, classes}>\n#{content}\n</aside>\n)
      end

      def convert_stem(node)
        open, close = BLOCK_MATH_DELIMITERS[node.style.to_sym]
        equation = node.content || ""
        equation = "#{open}#{equation}#{close}" unless (equation.start_with? open) && (equation.end_with? close)
        classes = ["stem", node.role].compact
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

      def convert_inline_footnote(node)
        if (index = node.attr "index")
          icon = %(<i class="bi bi-question-circle-fill"></i>)
          %(<sup>#{Utils.popover_button icon, "_footnotedef_#{index}", "fnref"}</sup>)
        else
          %(<sup class="text-danger">[??]</sup>)
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
        title = Utils.display_title(node)
        content = title + pre_open + node.content + pre_close
        Utils.wrap_node content, node
      end

      def convert_literal(node)
        nowrap = !(node.document.attr? "prewrap") || (node.option? "nowrap")
        pre = %(<pre#{%( class="nowrap") if nowrap}>#{node.content}</pre>)
        title = Utils.display_title(node)
        Utils.wrap_node "#{title}#{pre}", node
      end

      def convert_open(node)
        collapsible = node.option? "collapsible"
        title = if collapsible
                  %(<summary>#{node.title || "Details"}</summary>\n)
                else
                  Utils.display_title(node)
                end
        tag_name = collapsible ? :details : :div
        Utils.wrap_node(title + node.content, node, tag_name)
      end

      def convert_example(node)
        Utils.wrap_node_with_title node.content, node
      end

      def convert_image(node)
        content = display_figure node
        Utils.wrap_id_classes content, node.id, ["figbox", node.role].compact.join(" ")
      end

      def convert_inline_image(node)
        target = node.target
        return read_svg_contents(node, target) if node.option?("inline")

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
        node_text = node.text
        if node.type == :xref
          target = node.document.catalog[:refs][node.attr("refid")]
          if target&.inline? && target.parent&.parent&.style == "bibliography"
            reftext = target.reftext
            if node_text
              /\A\[(?<numeral>\d+)\]\z/ =~ reftext
              reftext = if numeral
                          "[#{numeral}, #{node_text}]"
                        else
                          "#{reftext}, #{node_text}"
                        end
            end
            return Utils.popover_button(reftext, target.id, "bibref")
          end

          if !node_text && (text = target&.inline? ? target&.text : target&.attr("reftext"))
            subs = %i[specialcharacters quotes replacements macros]
            return %(<a href="#{node.target}">#{node.apply_subs text, subs}</a>)
          end
        end
        super
      end

      def convert_table(node)
        classes = ["table", node.role].compact
        classes << "table-striped" if node.option? "striped"
        classes << "table-bordered" if node.option? "bordered"
        classes << "table-sm" if node.option? "compact"
        width_attribute = ""
        if (autowidth = node.option? "autowidth") && !(node.attr? "width")
          classes << "table-fit"
        elsif (tablewidth = node.attr "width")
          width_attribute = %( width="#{tablewidth}%")
        end
        result = [%(<table#{Utils.id_class_attr_str node.id, classes.join(" ")}#{width_attribute}>)]
        result << %(<caption class="table-title">#{Utils.display_title_prefix node}#{node.title}</caption>)
        if node.attr("rowcount").positive? && node.attr?("cols")
          result << "<colgroup>"
          if autowidth
            result += (Array.new node.columns.size, %(<col>))
          else
            node.columns.each do |col|
              result << (col.option?("autowidth") ? %(<col>) : %(<col style="width:#{col.attr "colpcwidth"}%;">))
            end
          end
          result << "</colgroup>"
        end
        result << "#{Table.display_rows(node)}</table>"
        Utils.wrap_id_classes result.join("\n"), nil, "table-responsive"
      end
    end
  end
end
