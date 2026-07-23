# frozen_string_literal: true

require_relative "utils"

module Asciidoctor
  module Html
    # Helpers for the table conversion
    module Table
      def self.display_row(tsec, row, line_number, live: false)
        result = ["<tr#{Utils.line_number_attr line_number, live:}>"]
        row.each do |cell|
          cell_content = if tsec == :head
                           cell.text
                         elsif cell.style == :literal
                           "<pre>#{cell.text}</pre>"
                         elsif cell.style == :asciidoc
                           cell.content
                         else
                           cell.content.join "\n"
                         end
          cell_tag_name = (tsec == :head || cell.style == :header ? "th" : "td")
          cell_attrs = []
          cell_attrs << %(halign-#{cell.attr "halign"}) unless cell.attr?("halign", "left")
          cell_attrs << %(align-#{cell.attr "valign"}) unless cell.attr?("valign", "top")
          cell_class_attribute = %( class="#{cell_attrs.join " "}") unless cell_attrs.empty?
          cell_colspan_attribute = cell.colspan ? %( colspan="#{cell.colspan}") : ""
          cell_rowspan_attribute = cell.rowspan ? %( rowspan="#{cell.rowspan}") : ""
          cell_attributes = "#{cell_class_attribute}#{cell_colspan_attribute}#{cell_rowspan_attribute}"
          result << %(<#{cell_tag_name}#{cell_attributes}>#{cell_content}</#{cell_tag_name}>)
        end
        result << "</tr>"
        result.join "\n"
      end

      def self.display_rows(node)
        line_number = 0
        live = node.attr? "live"
        node.rows.to_h.map do |tsec, rows|
          next if rows.empty?

          result = rows.map do |row|
            show_lineno = live && tsec != :head
            line_number += 1 if show_lineno
            display_row(tsec, row, line_number, live: show_lineno)
          end
          "<t#{tsec}>\n#{result.join "\n"}\n</t#{tsec}>"
        end.join("\n")
      end
    end
  end
end
