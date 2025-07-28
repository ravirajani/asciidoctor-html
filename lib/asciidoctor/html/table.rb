# frozen_string_literal: true

module Asciidoctor
  module Html
    # Helpers for the table conversion
    module Table
      def self.display_row(tsec, row)
        result = ["<tr>"]
        row.each do |cell|
          cell_content = if tsec == :head
                           cell.text
                         elsif cell.style == :literal
                           "<pre>#{cell.text}</pre>"
                         else
                           cell.content.join "\n"
                         end
          cell_tag_name = (tsec == :head || cell.style == :header ? %(th scope="col") : "td")
          cell_class_attribute = %( class="halign-#{cell.attr "halign"} align-#{cell.attr "valign"}")
          cell_colspan_attribute = cell.colspan ? %( colspan="#{cell.colspan}") : ""
          cell_rowspan_attribute = cell.rowspan ? %( rowspan="#{cell.rowspan}") : ""
          cell_attributes = "#{cell_class_attribute}#{cell_colspan_attribute}#{cell_rowspan_attribute}"
          result << %(<#{cell_tag_name}#{cell_attributes}>#{cell_content}</#{cell_tag_name}>)
        end
        result << "</tr>"
        result.join "\n"
      end

      def self.display_rows(node)
        node.rows.to_h.map do |tsec, rows|
          next if rows.empty?

          "<t#{tsec}>\n#{rows.map { |row| display_row(tsec, row) }.join("\n")}\n</t#{tsec}>"
        end.join("\n")
      end
    end
  end
end
