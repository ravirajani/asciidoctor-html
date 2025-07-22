# frozen_string_literal: true

require "asciidoctor"
require "pathname"

module Asciidoctor
  module Html
    # Insert an icon from https://icons.getbootstrap.com/
    class BiInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl

      named :bi
      name_positional_attributes "size", "color"

      def process(parent, target, attrs)
        s_attr = c_attr = nil
        s_attr = "font-size:#{attrs["size"]};" if attrs.include?("size")
        c_attr = "color:#{attrs["color"]};" if attrs.include?("color")
        attr_str = s_attr || c_attr ? %( style="#{s_attr}#{c_attr}") : ""
        icon = %(<i class="bi bi-#{target}"#{attr_str}></i>)
        create_inline_pass parent, icon
      end
    end
  end
end
