# frozen_string_literal: true

require_relative "utils"

module Asciidoctor
  module Html
    # Jupyterlite library
    module Jupyterlite
      CONFIG = {
        toolbar: true,
        kernel: "python",
        promptCellPosition: "left",
        clearCellsOnExecute: true,
        hideCodeInput: true,
        clearCodeContentOnExecute: false,
        showBanner: false,
        execute: false
      }.freeze

      def self.repl_path_with_options(node)
        query_string = ["code=#{URI.encode_uri_component node.content}"]
        query_string << CONFIG.merge(
          { promptCellPosition: node.attr("prompt-position", "top") }
        ).map do |k, v|
          value = if v == true
                    1
                  elsif v == false
                    0
                  else
                    v
                  end
          "#{k}=#{URI.encode_uri_component value}"
        end
        "#{node.document.attr "repl-url"}?#{query_string.join "&"}"
      end

      def self.html(node)
        error_msg = "Set a <code>repl_url</code> in your <code>config.yaml</code>."
        return Utils.show_error(error_msg) unless node.document.attr("repl-url")

        cell_id = "jupyter-cell-frame-#{node.attr "jupyter-cell-id"}"
        styles = []
        styles << "height:#{node.attr "height"}px;" if node.attr?("height")
        styles << "width:#{node.attr "width"}px;" if node.attr?("width")
        style_attr = %( style="#{styles.join}") unless styles.empty?
        <<~HTML
          <div id="#{cell_id}"#{style_attr} class="jupyter-cell"></div>
          <script>
            (function(){
              const cell = document.getElementById('#{cell_id}');
              addEventListener('load', () => {
                const frame = document.createElement('iframe');
                frame.src = '#{repl_path_with_options node}';
                frame.width = '100%';
                frame.height = '100%';
                cell.appendChild(frame);
              });
            })();
          </script>
        HTML
      end
    end
  end
end
