# frozen_string_literal: true

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
          { promptCellPosition: node.attr("prompt-position", "left") }
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
        return <<~HTML unless node.document.attr("repl-url")
          <p class="border border-danger p-2">Set a <code>repl_url</code> in your <code>config.yaml</code>.</p>
        HTML

        cell_id = "jupyter-cell-frame-#{node.attr "jupyter-cell-id"}"
        height_attr = %( style="height: #{node.attr("height")}px;") if node.attr?("height")
        <<~HTML
          <div id="#{cell_id}"#{height_attr} class="jupyter-cell"></div>
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
