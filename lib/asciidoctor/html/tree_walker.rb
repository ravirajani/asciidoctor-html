# frozen_string_literal: true

module Asciidoctor
  module Html
    # Walks the document tree
    class TreeWalker
      def initialize(document, max_levels = 5)
        @max_levels = max_levels
        @idx = [0] * (max_levels + 1) # index of next unexplored block at each level
        @path = [document]
        @level = 0 # the current level
      end

      def next_block
        return nil if @path.empty?

        @path.last
      end

      def walk
        block = next_block
        return nil unless block

        if block.blocks? && @level < @max_levels
          if @idx[@level + 1] < block.blocks.size
            @level += 1
            @path.push(block.blocks[@idx[@level]])
          else
            @idx[@level + 1] = 0
            retreat
          end
        else
          retreat
        end
      end

      def retreat
        @idx[@level] += 1
        @level -= 1
        @path.pop
      end
    end
  end
end
