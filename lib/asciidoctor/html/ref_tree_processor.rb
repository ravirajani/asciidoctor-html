# frozen_string_literal: true

require_relative "utils"
require_relative "tree_walker"

module Asciidoctor
  module Html
    # Traverses the document tree and attaches a correct reftext to
    # numbered nodes.
    class RefTreeProcessor < Asciidoctor::Extensions::TreeProcessor
      NUMBERED_CONTEXTS = {
        example: "thm-number",
        table: "tbl-number",
        image: "fig-number",
        olist: "fig-number"
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

      def uncaptioned_list?(context, env)
        context == :olist && env != "figlist"
      end

      def process_numbered_block!(block, document, sectnum)
        context = block.context
        env = (block.style || context).to_s
        env = "figure" if context == :image || env == "figlist"
        block.set_attr "showcaption", true unless uncaptioned_list?(context, env)
        block.set_attr "env", env
        assign_numeral! block, document, NUMBERED_CONTEXTS[context]
        title_prefix = "#{env.capitalize} #{relative_numeral block, document, sectnum}"
        block.set_attr "reftext", title_prefix
      end

      def reset_counters!(document)
        counters = document.counters
        NUMBERED_CONTEXTS.each_value do |counter_name|
          counters[counter_name] = 0
        end
      end

      def process(document)
        sectnum = 0
        tw = TreeWalker.new(document)
        while (block = tw.next_block)
          context = block.context
          unless block.attr? "refprocessed"
            if NUMBERED_CONTEXTS.key? context
              process_numbered_block! block, document, sectnum
            elsif context == :section && block.level == 1 && number_within(document) == :section
              sectnum += 1
              reset_counters! document
            end
            block.set_attr "refprocessed", true
          end
          tw.walk
        end
      end
    end
  end
end
