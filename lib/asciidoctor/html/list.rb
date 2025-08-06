# frozen_string_literal: true

module Asciidoctor
  module Html
    # Helper functions for the list conversion
    module List
      def self.convert(node, tag_name = :ol)
        depth = node.attr "list-depth"
        flat = node.attr? "flat-style"
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
        result = [%(<#{tag_name}#{Utils.dyn_id_class_attr_str node, classes.join(" ")}>)]
        node.items.each do |item|
          result << display_list_item(item)
        end
        result << %(</#{tag_name}> <!-- .level-#{level} -->\n)
        Utils.wrap_id_classes_with_title result.join("\n"), node, node.id, "list-wrapper"
      end

      def self.display_list_item(item)
        result = []
        result << %(<li#{Utils.id_class_attr_str item.id,
                                                 item.role}><div class="li-mark">#{item.attr "mark"}</div>)
        result << %(<div class="li-content"><p>#{item.text}</p>)
        result << "\n#{item.content}" if item.blocks?
        result << %(</div></li>#{Utils.id_class_sel_comment item.id, item.role})
        result.join "\n"
      end
    end
  end
end
