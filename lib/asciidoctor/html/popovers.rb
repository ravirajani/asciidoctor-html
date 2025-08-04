# frozen_string_literal: true

module Asciidoctor
  module Html
    # Configure the popovers for footnotes and citations.
    module Popovers
      POPOVERS = <<~JS
        (function() {
          let popoversInitialised = false
          function initPopovers() {
            document.querySelectorAll(".btn-po[data-contentid]").forEach(el => {
              const id = el.dataset.contentid;
              let content = document.getElementById(id);
              if(content) {
                if(content.tagName == "A") {
                  // This is an anchor of a bibitem
                  const listItem = content.parentElement.cloneNode(true)
                  listItem.removeChild(listItem.firstChild)
                  content = listItem
                }
                new bootstrap.Popover(el, {
                  trigger: "focus",
                  content: content,
                  html: true,
                  sanitize: false
                });
              }
            });
            popoversInitialised = true
          }
          MathJax = {
            startup: {
              pageReady: function() {
                return MathJax.startup.defaultPageReady().then(initPopovers);
              }
            }
          };
          addEventListener("load", function() {
            // Enable tooltips on images
            document.querySelectorAll('img[data-bs-toggle="tooltip"]').forEach(el => {
              bootstrap.Tooltip.getOrCreateInstance(el);
            });
            // Initialise Popovers if not already done
            if(!popoversInitialised) initPopovers();
          });
        })();
      JS
    end
  end
end
