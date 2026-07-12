# frozen_string_literal: true

require "asciidoctor"

module Asciidoctor
  module Html
    # Inserts a subnav for current chapter
    class SubnavBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
      use_dsl

      named :subnav

      def process(parent, _target, attrs)
        create_pass_block parent, %(<%= subnav %>), attrs, subs: nil
      end
    end
  end
end
