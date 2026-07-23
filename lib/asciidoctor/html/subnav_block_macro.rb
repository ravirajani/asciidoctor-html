# frozen_string_literal: true

require "asciidoctor"
require "pathname"

module Asciidoctor
  module Html
    # Inserts a subnav for a chapter
    class SubnavBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
      use_dsl

      named :subnav
      name_positional_attributes "title"

      def process(parent, target, attrs)
        doc_key = Pathname(target).sub_ext "" unless target.empty?
        title = %(<h5 class="block-title">#{parent.apply_subs attrs["title"]}</h5>) if attrs.include?("title")
        bordered_class = " bordered" if attrs.include?("border")
        border_width = attrs["border"].to_i if bordered_class
        style = %( style="border-top-width: #{border_width}px; border-bottom-width: #{border_width}px;") if border_width
        roles = " #{attrs["role"]}" if attrs.include?("role")
        content = <<~HTML
          <div class="subnav#{bordered_class}#{roles}"#{style}>
            #{title}
            <nav>
            <%= templates.dig("#{doc_key}", "outline") || outline %>
            </nav>
          </div>
        HTML
        content = Utils.wrap_live content, attrs["live"]
        create_pass_block parent, content, attrs, subs: nil
      end
    end
  end
end
