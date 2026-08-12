# frozen_string_literal: true

module Asciidoctor
  module Html
    # Helper functions for the image/figure conversion.
    # Mixed into the Converter class.
    module Figure
      def display_image(node, target, title_attr: false)
        return read_svg_contents(node, target) if node.option?("inline")

        attrs = image_attrs(node, title_attr:)
        %(<img src="#{node.image_uri target}" #{attrs}#{@void_element_slash}>)
      end

      def image_attrs(node, title_attr: false)
        width = node.attr?("width") ? %( width="#{node.attr "width"}") : ""
        height = node.attr?("height") ? %( height="#{node.attr "height"}") : ""
        title = encode_attribute_value node.attr("title") if node.attr?("title") && title_attr
        title = title ? %( data-bs-toggle="tooltip" data-bs-title="#{title}") : ""
        alt = encode_attribute_value node.alt
        %(alt="#{alt}"#{width}#{height}#{title})
      end

      def display_figure(node)
        target = node.attr "target"
        title = node.title if node.title?
        image = display_image node, target
        caption = %(    <figcaption>#{Utils.display_title_prefix node}#{title}</figcaption>\n) if Utils.show_title?(node)
        %(<figure>\n    #{image}\n#{caption}</figure>)
      end

      def convert_figlist(node)
        tagname = node.context == :olist ? :ol : :ul
        result = node.items.map do |item|
          %(<li#{Utils.id_class_attr_str item.id, item.role}><figure>\n#{item.text}\n</figure></li>)
        end
        content = Utils.wrap_id_classes result.join("\n"), nil, "figlist", tagname
        title = if Utils.show_title?(node)
                  %(<div class="figlist-title">#{Utils.display_title_prefix(node)}#{node.title}</div>)
                end
        classes = ["figlist-wrapper", node.role].compact.join(" ")
        Utils.wrap_id_classes %(#{content}#{title}), node.id, classes
      end
    end
  end
end
