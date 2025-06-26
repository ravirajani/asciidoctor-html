# frozen_string_literal: true

require "roman-numerals"

module Asciidoctor
  module Html
    # Helper functions for the olist conversion
    module Olist
      DEPTH_ATTR = "list-depth"
      OFFSET_ATTR = "list-offset"
      FLAT_STYLE = "pseudocode"

      def self.depth(node)
        unless node.attr?(DEPTH_ATTR)
          parent = node.parent
          parent = parent.parent until parent.context == :olist || !parent.parent
          node.set_attr(DEPTH_ATTR, parent.attr?(DEPTH_ATTR) ? (parent.attr(DEPTH_ATTR) + 1) : 0)
        end
        node.attr DEPTH_ATTR
      end

      # Finds first parent node with OFFSET_ATTR (numbering follows this if so).
      # If node.style == FLAT_STYLE, then OFFSET_ATTR is set to (start || 0) on node, and node is returned.
      # Otherwise nil is returned.
      def self.parent_with_offset(node)
        node.set_attr OFFSET_ATTR, default_offset(node) if node.style == FLAT_STYLE
        unless node.attr? OFFSET_ATTR
          parent = node.parent
          parent = parent.parent until parent.attr?(OFFSET_ATTR) || !parent.parent
          return parent if parent.attr? OFFSET_ATTR
        end
        node.attr?(OFFSET_ATTR) ? node : nil
      end

      def self.default_offset(node)
        start = node.attr?("start") ? node.attr("start") : 1
        num = start.to_i
        num.to_s == start ? (num - 1) : 0
      end

      def self.increment_offset!(parent, step = 1)
        if parent&.attr?(OFFSET_ATTR)
          offset = parent.attr OFFSET_ATTR
          parent.set_attr(OFFSET_ATTR, offset + step)
          return offset
        end
        0
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

      def self.convert_list_item(node, parent, depth, item, idx)
        depth = 0 if parent # Number relative to parent's offset if parent != nil
        adj_idx = parent ? increment_offset!(parent) : (idx + default_offset(node))
        display_list_item item, depth, adj_idx
      end

      def self.display_list_item(item, depth, idx)
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
