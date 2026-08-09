# frozen_string_literal: true

module Asciidoctor
  module Html
    # Constants for the jupyterlite library
    module Jupyterlite
      @@id = 0

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
        execute: false,
        theme: "JupyterLab Dark"
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
        @@id += 1
        spinner_id = "jupyter-cell-spinner-#{@@id}"
        cell_id = "jupyter-cell-frame-#{@@id}"
        height_attr = %( style="height: #{node.attr("height")}px;") if node.attr?("height")
        <<~HTML
        <div id="#{cell_id}"#{height_attr}>
          <div id="#{spinner_id}" class="d-flex justify-content-center align-items-center"#{height_attr}>
            <div class="spinner-border" role="status">
              <span class="visually-hidden">Loading...</span>
            </div>
          </div>
        </div>
        <script>
          (function(){
            const spinner = document.getElementById('#{spinner_id}');
            const cell = document.getElementById('#{cell_id}');
            addEventListener('load', () => {
              const frame = document.createElement('iframe');
              frame.classList.add('hidden');
              frame.src = '#{PATH}/#{repl_path_with_options node}';
              frame.width = '100%';
              frame.height = '100%';
              cell.appendChild(frame);
              frame.addEventListener('load', () => {
                spinner.classList.add('hidden');
                frame.classList.remove('hidden');
              });
            });
          })();
        </script>
        HTML
      end
    end
  end
end
