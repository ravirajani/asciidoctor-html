# frozen_string_literal: true

require "asciidoctor"
require "roman-numerals"
require_relative "tree_walker"
require_relative "highlightjs"

module Asciidoctor
  module Html
    # Traverses the document tree and:
    # - attaches a correct reftext to numbered nodes;
    # - populates the text (= reftext for inline nodes) of anchors at
    #   the beginning of a list item for an ordered list;
    # - registers every encountered source code language not included
    #   in the default highlightjs build.
    class RefTreeProcessor < Asciidoctor::Extensions::TreeProcessor
      NUMBERED_CONTEXTS = {
        example: "thm-number",
        table: "tbl-number",
        image: "fig-number",
        stem: "eqn-number",
        listing: "ltg-number"
      }.freeze

      def assign_numeral!(node, document, counter_name)
        document.counters[counter_name] ||= 0
        node.numeral = (document.counters[counter_name] += 1)
      end

      def relative_numeral(node, document)
        return "" unless node.numeral

        chapnum = document.attr "chapnum"
        has_prefix = chapnum && !chapnum.empty? && chapnum != "0"
        has_prefix ? "#{chapnum}.#{node.numeral}" : node.numeral.to_s
      end

      def process_numbered_block!(block, document)
        context = block.context
        style = block.style
        context = :image if style == "figlist"
        env = env context, style
        block.set_attr("showcaption", true) unless context == :stem
        assign_numeral! block, document, NUMBERED_CONTEXTS[context]
        relative_numeral = relative_numeral block, document

        reftext = if context == :stem
                    "(#{relative_numeral})"
                  else
                    "#{env.capitalize} #{relative_numeral}"
                  end
        block.set_attr "reftext", reftext unless block.reftext?
        block.set_attr "title-prefix", reftext
      end

      def env(context, style)
        case context
        when :image then "figure"
        when :stem then "equation"
        when :listing then "listing"
        else style || context.to_s
        end
      end

      def process_numbered_block?(block)
        context = block.context
        case context
        when :olist
          block.style == "figlist"
        when :stem, :listing
          block.option? "numbered"
        else
          NUMBERED_CONTEXTS.include? context
        end
      end

      def convert_mark(numeral, idx)
        case numeral
        when "a" then ("a".."z").to_a[idx]
        when "A" then ("a".."z").to_a[idx].upcase
        when "I" then RomanNumerals.to_roman(idx + 1)
        when "i" then RomanNumerals.to_roman(idx + 1).downcase
        else idx + 1
        end
      end

      def li_default_format(depth, style = nil)
        return "[1]" if style == "bibliography"
        return "(a)" if style == "figlist"

        case depth
        when 1 then "(a)"
        when 2 then "i."
        when 3 then "(A)"
        else "1."
        end
      end

      def li_ref_mark(mark)
        return mark[0..-2] if mark.end_with?(".")

        mark
      end

      def li_mark(node, idx, depth, format_str)
        rgx = /(?<left>.?)(?<numeral>[1iIaA])(?<right>.?)/
        match = rgx.match(format_str) || rgx.match(li_default_format(depth))
        delim_left = node.sub_specialchars match[:left]
        delim_right = node.sub_specialchars match[:right]
        mark = convert_mark match[:numeral], idx
        ->(prefix) { "#{delim_left}#{prefix}#{mark}#{delim_right}" }
      end

      def bullet(depth)
        case depth
        when 1 then "&#8208;"
        when 2 then "&#11089;"
        when 3 then "&#9702;"
        else "&#8226;"
        end
      end

      def offset(list)
        return (list.attr("start").to_i - 1) if list.attr?("start")
        return 0 unless list.attr?("continue")

        id = list.attr "continue"
        node = list.document.catalog[:refs][id]
        return node.attr("nflatitems") || node.items.size if node&.context == :olist

        0
      end

      # Finds an anchor at the start of item.text and updates
      # its reftext to that of item's if necessary.
      def register_reftext!(item, reftext)
        item.set_attr "reftext", reftext
        /\A<a id="(?<anchor_id>.+?)"/ =~ item.text
        node = item.document.catalog[:refs][anchor_id]
        node&.text ||= reftext
      end

      def process_olist!(block, depth, flat_style: false)
        relative = block.option? "relative"
        parent_mark = "#{block.document.attr "chapnum"}." if relative
        parent_reftext = ""
        if depth.positive?
          parent = block.parent
          parent = parent.parent until parent.context == :list_item
          parent_reftext = parent.reftext if parent.reftext?
          parent_mark = parent.attr "mark" if relative
        end
        block.set_attr "list-depth", depth
        if flat_style
          block.set_attr("flat-style", true)
        else
          offset = offset block
          style = block.style
          marker_format = block.attr("markers") || li_default_format(depth, style)
          block.items.each_with_index do |item, idx|
            mark = li_mark(block, idx + offset, depth, marker_format)
            item.set_attr "mark", mark.call(parent_mark)
            ref_mark_prefix = parent_mark if depth.zero?
            register_reftext! item, "#{parent_reftext}#{li_ref_mark mark.call(ref_mark_prefix)}"
          end
        end
      end

      def process_colist!(block)
        block.set_attr "list-depth", 0
        block.items.each_with_index do |item, idx|
          icon_type = "#{idx + 1}-circle"
          icon = %(<i class="bi bi-#{icon_type}"></i>)
          item.set_attr "mark", icon
          register_reftext! item, "bi:#{icon_type}[]"
        end
      end

      def process_ulist!(block, depth)
        block.set_attr "list-depth", depth
        block.items.each do |item|
          is_checkbox = item.attr? "checkbox"
          icon_class = item.attr?("checked") ? "check-" : ""
          icon = %(<i class="bi bi-#{icon_class}square"></i>)
          mark = is_checkbox ? icon : bullet(depth)
          item.role = "checked" if is_checkbox
          item.set_attr "mark", mark
        end
      end

      def process_flat_item!(item, idx)
        mark = (idx + 1).to_s
        item.set_attr "mark", mark
        register_reftext! item, mark
      end

      def process_source_code!(document, lang)
        document.set_attr("source-langs", {}) unless document.attr?("source-langs")
        langs = document.attr "source-langs"
        langs[lang] = true unless Highlightjs::INCLUDED_LANGS.include?(lang)
      end

      def olist_item?(node)
        node.context == :list_item && node.parent.context == :olist
      end

      def ulist_item?(node)
        node.context == :list_item && node.parent.context == :ulist
      end

      def ulist?(node)
        node.context == :ulist
      end

      def olist?(node)
        node.context == :olist
      end

      def colist?(node)
        node.context == :colist
      end

      def source_code?(node)
        node.context == :listing && node.style == "source" && node.attr?("language")
      end

      def process(document)
        listdepth = 0
        bulletdepth = 0
        flat_style = false
        flat_idx = 0 # flat index for (pseudocode) list
        tw = TreeWalker.new document
        while (block = tw.next_block)
          unless block.attr? "refprocessed"
            process_numbered_block!(block, document) if process_numbered_block?(block)
            if colist? block
              process_colist! block
            elsif olist? block
              if listdepth.zero?
                flat_style = (block.style == "pseudocode")
                flat_idx = offset block
              end
              process_olist! block, listdepth, flat_style:
            elsif olist_item?(block) && flat_style
              process_flat_item! block, flat_idx
              flat_idx += 1
            elsif source_code? block
              process_source_code! document, block.attr("language")
            elsif ulist? block
              process_ulist! block, bulletdepth
            end
            block.set_attr "refprocessed", true
          end
          tw.walk do |move|
            listdepth += 1 if olist?(block) && move == :explore
            listdepth -= 1 if olist_item?(block) && move == :retreat
            bulletdepth += 1 if ulist?(block) && move == :explore
            bulletdepth -= 1 if ulist_item?(block) && move == :retreat
            block.set_attr("nflatitems", flat_idx) if olist?(block) && flat_style && move == :retreat
          end
        end
      end
    end
  end
end
