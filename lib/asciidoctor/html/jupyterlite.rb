# frozen_string_literal: true

module Asciidoctor
  module Html
    # Constants for the jupyterlite library
    module Jupyterlite
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

      def self.path_with_options(node)
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
        <<~HTML
          <iframe
            src="#{node.document.attr("jupyterlite-url")}#{path_with_options node}"
            width="100%"
            height=#{node.attr("height", "100%")}
            loading="lazy"
          ></iframe>
        HTML
      end
    end
  end
end
