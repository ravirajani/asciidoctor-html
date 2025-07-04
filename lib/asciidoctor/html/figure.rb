# frozen_string_literal: true

require_relative "olist"

module Asciidoctor
  module Html
    # Helper functions for the image/figure conversion.
    # Mixed into the Converter class.
    module Figure
      def display_image(node, target, attrs)
        %(<img src="#{node.image_uri target}" #{attrs}#{@void_element_slash}>)
      end

      def image_attrs(node)
        width = node.attr?("width") ? %( width="#{node.attr "width"}") : ""
        height = node.attr?("height") ? %( height="#{node.attr "height"}") : ""
        alt = encode_attribute_value node.alt
        %(alt="#{alt}"#{width}#{height})
      end

      def display_figure(node)
        target = node.attr "target"
        title = node.title? ? node.title : ""
        attrs = image_attrs node
        image = display_image node, target, attrs
        caption = %(<figcaption>#{Utils.display_title_prefix node}#{title}</figcaption>)
        %(<figure>\n    #{image}\n    #{caption}\n</figure>)
      end

      def convert_figlist(node)
        result = node.items.map do |item|
          %(<li#{Utils.id_class_attr_str item.id}><figure>\n#{item.text}\n</figure></li>)
        end
        content = Utils.wrap_id_classes result.join("\n"), nil, "figlist loweralpha", :ol
        title = if Utils.show_title?(node)
                  %(<div class="figlist-title">#{Utils.display_title_prefix(node)}#{node.title}</div>)
                else
                  ""
                end
        classes = ["figlist-wrapper", node.role].compact.join(" ")
        Utils.wrap_id_classes %(#{content}#{title}), node.id, classes
      end
    end
  end
end
