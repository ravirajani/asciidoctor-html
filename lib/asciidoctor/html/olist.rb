# frozen_string_literal: true

module Asciidoctor
  module Html
    # Helper functions for the olist conversion.
    module Olist
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
