# frozen_string_literal: true

require "roman-numerals"
require_relative "tree_walker"

module Asciidoctor
  module Html
    # Traverses the document tree and attaches a correct reftext to
    # numbered nodes.
    class RefTreeProcessor < Asciidoctor::Extensions::TreeProcessor
      NUMBERED_CONTEXTS = {
        example: "thm-number",
        table: "tbl-number",
        image: "fig-number"
      }.freeze

      def number_within(document)
        return :chapter if document.attr? "chapnum"
        return :section if document.attr? "sectnums"

        :document
      end

      def assign_numeral!(node, document, counter_name)
        document.counters[counter_name] ||= 0
        node.numeral = (document.counters[counter_name] += 1)
      end

      def relative_numeral(node, document, sectnum)
        if node.numeral
          prefix_number = (document.attr("chapnum") || sectnum).to_i
          prefix_number.positive? ? "#{prefix_number}.#{node.numeral}" : node.numeral.to_s
        else
          ""
        end
      end

      def process_numbered_block!(block, document, sectnum)
        context = block.context
        env = (block.style || context).to_s
        env = "figure" if context == :image || env == "figlist"
        block.set_attr "showcaption", true
        assign_numeral! block, document, NUMBERED_CONTEXTS[context]
        title_prefix = "#{env.capitalize} #{relative_numeral block, document, sectnum}"
        block.set_attr "reftext", title_prefix
      end

      def process_numbered_block?(block)
        NUMBERED_CONTEXTS.key?(block.context) || block.style == "figlist"
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
            item.set_attr("reftext", "#{parent_reftext}#{ref_li_mark mark, d}")
          end
        end
      end

      def process_flat_item!(item, idx)
        mark = li_mark(0, idx)
        item.set_attr "mark", mark
        item.set_attr "reftext", ref_li_mark(mark, 0)
      end

      def reset_counters!(document)
        counters = document.counters
        NUMBERED_CONTEXTS.each_value do |counter_name|
          counters[counter_name] = 0
        end
      end

      def process(document)
        sectnum = 0
        listdepth = 0
        flat_style = false
        flat_idx = 0 # flat index for (pseudocode) list
        tw = TreeWalker.new(document)
        while (block = tw.next_block)
          context = block.context
          unless block.attr? "refprocessed"
            process_numbered_block!(block, document, sectnum) if process_numbered_block?(block)
            if context == :section && block.level == 1 && number_within(document) == :section
              sectnum += 1
              reset_counters! document
            elsif context == :olist
              if listdepth.zero?
                flat_style = (block.style == "pseudocode")
                flat_idx = offset block
              end
              process_olist!(block, listdepth, flat_style:)
            elsif context == :list_item && flat_style
              process_flat_item!(block, flat_idx)
              flat_idx += 1
            end
            block.set_attr "refprocessed", true
          end
          tw.walk do |move|
            listdepth += 1 if context == :olist && move == :explore
            listdepth -= 1 if context == :list_item && move == :retreat
          end
        end
      end
    end
  end
end
