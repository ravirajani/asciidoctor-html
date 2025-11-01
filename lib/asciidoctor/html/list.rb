# frozen_string_literal: true

module Asciidoctor
  module Html
    # Helper functions for the list conversion
    module List
      def self.convert(node, tag_name = :ol)
        depth = node.attr "list-depth"
        flat = node.attr? "flat-style"
        inside = node.option? "inside"
        level = depth + 1
        classes = [
          "list",
          "list-#{node.context}",
          ("level-#{level} pseudocode" if flat),
          node.role
        ].compact
        classes << "list-checklist" if node.option?("checklist")
        classes << "list-unmarked" if node.option?("unmarked")
        classes << "list-roomy" if node.option?("roomy")
        classes << "list-inside" if inside
        result = [%(<#{tag_name}#{Utils.dyn_id_class_attr_str node, classes.join(" ")}>)]
        node.items.each do |item|
          result << display_list_item(item, inside:)
        end
        result << %(</#{tag_name}> <!-- .level-#{level} -->\n)
        Utils.wrap_id_classes_with_title result.join("\n"), node, node.id, "list-wrapper"
      end

      def self.display_list_item(item, inside: false)
        result = []
        inside_mark = %(<span class="li-mark-inside">#{item.attr "mark"} </span>) if inside
        result << %(<li#{Utils.id_class_attr_str item.id, item.role}>)
        result << %(<div class="li-mark">#{item.attr "mark"}</div><div class="li-content">) unless inside
        result << %(<p>#{inside_mark}#{item.text}</p>) unless item.text.empty?
        result << "\n#{item.content}" if item.blocks?
        result << "</div>" unless inside
        result << %(</li>#{Utils.id_class_sel_comment item.id, item.role})
        result.join "\n"
      end
    end
  end
end
