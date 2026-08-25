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
          reftext = el && (attrs["reftext"] || Utils.reftext(el))
          title = %(<div class="block-title">#{parent.apply_subs attrs["title"]}</div>) if attrs.include?("title")
          content = if reftext
                      id = %( id="#{attrs["id"]}") if attrs.include?("id")
                      classes = %( #{attrs["role"]}) if attrs.include?("role")
                      <<~HTML
                        <div#{id} class="reuse#{classes}">
                          #{title}
                          <p><a href="##{target}">#{reftext}</a></p>
                        </div>
                      HTML
                    else
                      Utils.show_error "Invalid ID."
                    end
        end
        create_pass_block parent, content, attrs, subs: nil
      end
    end
  end
end
