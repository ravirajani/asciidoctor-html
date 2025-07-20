# frozen_string_literal: true

module Asciidoctor
  module Html
    # Constants for the highlightjs syntax highlighting library
    module Highlightjs
      CDN_PATH = "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.11.1/build"

      INCLUDED_LANGS = {
        "bash" => true,
        "c" => true,
        "cpp" => true,
        "csharp" => true,
        "css" => true,
        "diff" => true,
        "go" => true,
        "graphql" => true,
        "ini" => true,
        "java" => true,
        "javascript" => true,
        "json" => true,
        "kotlin" => true,
        "less" => true,
        "lua" => true,
        "makefile" => true,
        "markdown" => true,
        "objectivec" => true,
        "perl" => true,
        "php" => true,
        "php-template" => true,
        "plaintext" => true,
        "python" => true,
        "python-repl" => true,
        "r" => true,
        "ruby" => true,
        "rust" => true,
        "scss" => true,
        "shell" => true,
        "sql" => true,
        "swift" => true,
        "typescript" => true,
        "vbnet" => true,
        "wasm" => true,
        "xml" => true,
        "yaml" => true
      }.freeze

      COPY_PLUGIN = %[
      hljs.addPlugin({
        "after:highlightElement": function({ el, text }) {
          const wrapper = el.parentElement; // pre element
          if (wrapper == null) {
            return;
          }

          const copyButton = document.createElement("button");
          copyButton.classList.add("btn", "copy-button");
          copyButton.setAttribute("type", "button");

          const copyIcon = document.createElement("i");
          copyIcon.classList.add("bi", "bi-clipboard");

          copyButton.append(copyIcon);

          function toggleCopyIcon() {
            copyIcon.classList.toggle("bi-clipboard");
            copyIcon.classList.toggle("bi-clipboard-check");
          }

          copyButton.onclick = function() {
            navigator.clipboard.writeText(text);
            if(!copyIcon.classList.contains("bi-clipboard-check")) {
              toggleCopyIcon();
              setTimeout(toggleCopyIcon, 2000);
            }
          };

          // Append the copy button to the wrapper
          wrapper.appendChild(copyButton);
        }
      });].gsub(/^    /, "")
    end
  end
end
