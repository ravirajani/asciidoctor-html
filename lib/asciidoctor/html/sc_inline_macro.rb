# frozen_string_literal: true

require "asciidoctor"

module Asciidoctor
  module Html
    # Convert text to small caps
    class ScInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl

      named :sc
      name_positional_attributes "text"
      format :short

      def process(parent, target, _attrs)
        create_inline_pass parent, "[.smallcaps]##{target}#",
                           attributes: { "subs" => :normal }
      end
    end
  end
end
