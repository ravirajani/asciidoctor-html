# frozen_string_literal: true

require "asciidoctor"
require "pathname"

module Asciidoctor
  module Html
    # Allow cross references between documents by creating a suitable
    # ERB inline ruby string:
    #
    # cref:example.adoc#element-id[]
    # => <a href="example.html#"
    class CrefInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl

      named :cref
      name_positional_attributes "text"

      def process(parent, target, attrs)
        path_tag = target.split "#"
        path = path_tag.first
        tag = path_tag.size > 1 ? path_tag[1] : "doctitle"
        text = attrs["text"] || %(<%= refs["#{Pathname(path).sub_ext ""}"]["#{tag}"] %>)
        hash_tag = path_tag.size > 1 ? "##{path_tag[1]}}" : ""
        href = "#{Pathname(path).sub_ext ".html"}#{hash_tag}"
        create_anchor parent, text, type: :link, target: href
      end
    end
  end
end
