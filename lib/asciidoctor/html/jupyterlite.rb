# frozen_string_literal: true

module Asciidoctor
  module Html
    # Constants for the jupyterlite library
    module Jupyterlite
      @id = 0

      PATH = "jupyterlite"
      REPL_PATH = "repl/index.html"

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
        "#{REPL_PATH}?#{query_string.join "&"}"
      end

      def self.html(node)
        @id += 1
        cell_id = "jupyter-cell-frame-#{@id}"
        height_attr = %( style="height: #{node.attr("height")}px;") if node.attr?("height")
        <<~HTML
          <div id="#{cell_id}"#{height_attr} class="jupyter-cell"></div>
          <script>
            (function(){
              const cell = document.getElementById('#{cell_id}');
              addEventListener('load', () => {
                const frame = document.createElement('iframe');
                frame.src = '#{PATH}/#{repl_path_with_options node}';
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
