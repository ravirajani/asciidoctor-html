# frozen_string_literal: true

require "asciidoctor"

module Asciidoctor
  module Html
    # Format text according to Bootstrap-compatible inline text elements
    class TextInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl

      named :text
      name_positional_attributes "text"

      def process(parent, target, attrs)
        text = attrs["text"]
        content = case target
                  when "del"
                    %(<del>#{text}</del>)
                  when "strike"
                    %(<s>#{text}</s>)
                  when "ins"
                    %(<ins>#{text}</ins>)
                  when "underline"
                    %(<u>#{text}</u>)
                  when "small"
                    %(<small>#{text}</small>)
                  when "abbr"
                    title = %( title="#{attrs["title"]}" data-bs-toggle="tooltip") if attrs.include?("title")
                    role = %( class="#{attrs["role"]}") if attrs.include?("role")
                    %(<abbr#{title}#{role}>#{text}</abbr>)
                  else
                    %(<span class="text-#{target}">#{text}</span>)
                  end
        create_inline_pass parent, content
      end
    end
  end
end
