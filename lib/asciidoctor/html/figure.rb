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

      def convert_figlist_item(item, idx)
        item.set_attr "figcap-mark", Olist.list_mark(1, idx)
        %(<li><figure>\n#{item.text}\n</figure></li>)
      end

      def convert_figlist(node)
        result = []
        node.items.each_with_index do |item, idx|
          result << convert_figlist_item(item, idx)
        end
        content = Utils.wrap_id_classes result.join("\n"), nil, "figlist loweralpha", :ol
        title = Utils.display_title node
        classes = ["figlist-wrapper", node.role].compact.join(" ")
        Utils.wrap_id_classes %(#{content}#{title}), node.id, classes
      end
    end
  end
end
