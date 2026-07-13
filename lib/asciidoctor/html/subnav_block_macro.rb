# frozen_string_literal: true

require "asciidoctor"

module Asciidoctor
  module Html
    # Inserts a subnav for current chapter
    class SubnavBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
      use_dsl

      named :subnav
      name_positional_attributes "title"

      def process(parent, _target, attrs)
        title = %(<h5 class="block-title">#{attrs["title"]}</h5>) if attrs.include?("title")
        bordered_class = " bordered" if attrs.include?("border")
        border_width = attrs["border"].to_i if bordered_class
        style = %( style="border-top-width: #{border_width}px; border-bottom-width: #{border_width}px;") if border_width
        roles = attrs["role"] if attrs.include?("role")
        roles = attrs["roles"] if attrs.include?("roles")
        role = " #{roles.tr ",", " "}" if roles
        content = <<~HTML
          <div class="subnav#{bordered_class}#{role}"#{style}>
            #{title}
            <nav>
            <%= subnav %>
            </nav>
          </div>
        HTML
        create_pass_block parent, content, attrs, subs: nil
      end
    end
  end
end
