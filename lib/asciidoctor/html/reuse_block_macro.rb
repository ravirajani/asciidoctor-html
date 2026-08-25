# frozen_string_literal: true

require "asciidoctor"
require_relative "utils"

module Asciidoctor
  module Html
    # Reuse blocks, especially useful in multi mode
    class ReuseBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
      use_dsl

      named :reuse
      name_positional_attributes "reftext"

      def process(parent, target, attrs)
        if target.empty?
          content = Utils.show_error "Missing target."
        else
          el = parent.document.catalog[:refs][target]
          reftext = Utils.reftext el
          content = %(<div class="reuse"><p><a href="##{target}">#{reftext}</a></p></div>)
        end
        create_pass_block parent, content, attrs, subs: nil
      end
    end
  end
end
