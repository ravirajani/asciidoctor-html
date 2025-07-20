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
        has_prefix = chapnum && !chapnum.empty?
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
        block.set_attr "reftext", reftext
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

      def li_mark(depth, idx)
        case depth
        when 0
          idx + 1
        when 1
          ("a".."z").to_a[idx]
        when 2
          RomanNumerals.to_roman(idx + 1).downcase
        when 3
          ("a".."z").to_a[idx].upcase
        end
      end

      def ref_li_mark(mark, depth)
        return mark.to_s if depth.even?

        "(#{mark})"
      end

      def offset(list)
        list.attr?("start") ? (list.attr("start").to_i - 1) : 0
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
        parent_reftext = ""
        if depth.positive?
          parent = block.parent
          parent = parent.parent until parent.context == :list_item
          parent_reftext = parent.reftext? ? parent.reftext : ""
        end
        block.set_attr "list-depth", depth
        if flat_style
          block.set_attr("flat-style", true)
        else
          offset = offset block
          block.items.each_with_index do |item, idx|
            d = block.style == "figlist" ? 1 : depth
            mark = li_mark(d, idx + offset)
            item.set_attr "mark", mark
            item_reftext = "#{parent_reftext}#{ref_li_mark mark, d}"
            register_reftext! item, item_reftext
          end
        end
      end

      def process_colist!(block)
        block.set_attr "list-depth", 0
        block.items.each_with_index do |item, idx|
          icon = %(<i class="bi bi-#{idx + 1}-circle"></i>)
          item.set_attr "mark", icon
          register_reftext! item, icon
        end
      end

      def process_flat_item!(item, idx)
        mark = li_mark(0, idx)
        item.set_attr "mark", mark
        register_reftext! item, ref_li_mark(mark, 0)
      end

      def process_source_code!(document, lang)
        document.set_attr("source-langs", {}) unless document.attr?("source-langs")
        langs = document.attr "source-langs"
        langs[lang] = true unless Highlightjs::INCLUDED_LANGS.include?(lang)
      end

      def reset_counters!(document)
        counters = document.counters
        NUMBERED_CONTEXTS.each_value do |counter_name|
          counters[counter_name] = 0
        end
      end

      def olist_item?(node)
        node.context == :list_item && node.parent.context == :olist
      end

      def level1_section?(node)
        node.context == :section && node.level == 1
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
        flat_style = false
        flat_idx = 0 # flat index for (pseudocode) list
        tw = TreeWalker.new document
        while (block = tw.next_block)
          unless block.attr? "refprocessed"
            process_numbered_block!(block, document) if process_numbered_block?(block)
            if colist?(block)
              process_colist! block
            elsif olist?(block)
              if listdepth.zero?
                flat_style = (block.style == "pseudocode")
                flat_idx = offset block
              end
              process_olist!(block, listdepth, flat_style:)
            elsif olist_item?(block) && flat_style
              process_flat_item! block, flat_idx
              flat_idx += 1
            elsif source_code?(block)
              process_source_code! document, block.attr("language")
            end
            block.set_attr "refprocessed", true
          end
          tw.walk do |move|
            listdepth += 1 if olist?(block) && move == :explore
            listdepth -= 1 if olist_item?(block) && move == :retreat
          end
        end
      end
    end
  end
end
