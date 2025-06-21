# frozen_string_literal: true

require "roman-numerals"

module Asciidoctor
  module Html
    # Helper functions for the olist conversion
    module Olist
      DEPTH_ATTR = "list-depth"

      def self.depth(node)
        unless node.attr?(DEPTH_ATTR)
          parent = node.parent
          parent = parent.parent until parent.context == :olist || !parent.parent
          node.set_attr(DEPTH_ATTR, parent.attr?(DEPTH_ATTR) ? (parent.attr(DEPTH_ATTR) + 1) : 0)
        end
        node.attr DEPTH_ATTR
      end

      def self.list_mark(depth, idx)
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

      def self.convert_list_item(depth, item, idx)
        result = []
        result << %(<li#{Utils.id_class_attr_str item.id,
                                                 item.role}><div class="li-mark">#{Olist.list_mark depth, idx}</div>)
        result << %(<div class="li-content"><p>#{item.text}</p>)
        result << "\n#{item.content}" if item.blocks?
        result << %(</div></li>#{Utils.id_class_sel_comment item.id, item.role})
        result.join "\n"
      end
    end
  end
end
