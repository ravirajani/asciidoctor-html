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

      PLUGIN = %[
      const touch = matchMedia('(hover: none)').matches;
      function toggleCopyIcon(copyIcon) {
        copyIcon.classList.toggle("bi-clipboard");
        copyIcon.classList.toggle("bi-clipboard-check");
      }
      hljs.addPlugin({
        "after:highlightElement": function({ el, result, text }) {
          const wrapper = el.parentElement; // pre element
          if(wrapper == null) { return; }

          const overlay = document.createElement("div");
          overlay.classList.add("copy-button");
          overlay.textContent = result.language.toUpperCase() + ' ';

          const copyButton = document.createElement("button");
          copyButton.classList.add("btn");
          copyButton.setAttribute("type", "button");
          copyButton.setAttribute("data-bs-toggle", "tooltip");
          copyButton.setAttribute("data-bs-title", "Copy to clipboard");
          if(!touch) {bootstrap.Tooltip.getOrCreateInstance(copyButton);}

          const copyIcon = document.createElement("i");
          copyIcon.classList.add("bi", "bi-clipboard");

          copyButton.append(copyIcon);
          overlay.append(copyButton);

          copyButton.onclick = function() {
            navigator.clipboard.writeText(text);
            if(!copyIcon.classList.contains("bi-clipboard-check")) {
              toggleCopyIcon(copyIcon);
              setTimeout(() => { toggleCopyIcon(copyIcon); }, 1500);
            }
          };

          // Append the copy button to the wrapper
          wrapper.appendChild(overlay);

          // Find and replace inline callouts
          const rgx = /[\u2460-\u2468]/gu;
          if(text.match(rgx)) {
            text = text.replaceAll(rgx, "");
            el.innerHTML = el.innerHTML.replaceAll(rgx, (match) => {
              return '<i class="bi bi-' + (match.charCodeAt() - 9311) + '-circle"></i>';
            });
          }
        }
      });].gsub("\n      ", "\n")
    end
  end
end
