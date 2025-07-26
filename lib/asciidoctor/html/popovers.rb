# frozen_string_literal: true

module Asciidoctor
  module Html
    # Configure the popovers for footnotes and citations.
    module Popovers
      POPOVERS = <<~JS
        function initPopovers() {
          document.querySelectorAll(".btn-po[data-contentid]").forEach(btn => {
            const id = btn.dataset.contentid;
            let content = document.getElementById(id);
            if(content) {
              if(content.tagName == "A") {
                // This is an anchor of a bibitem
                const listItem = content.parentElement.cloneNode(true)
                listItem.removeChild(listItem.firstChild)
                content = listItem
              }
              new bootstrap.Popover(btn, {
                content: content,
                html: true,
                sanitize: false
              });
            }
          });
        }
        MathJax = {
          startup: {
            pageReady: function() {
              return MathJax.startup.defaultPageReady().then(initPopovers);
            }
          }
        };
      JS

      TOOLTIPS = <<~JS
        // Only enable tooltips on images if not a touch screen device
        if(!touch) {
          document.querySelectorAll('img[data-bs-toggle="tooltip"]').forEach(el => {
            bootstrap.Tooltip.getOrCreateInstance(el);
          });
        }
      JS

      INIT = "#{TOOLTIPS}\n#{POPOVERS}".freeze
    end
  end
end
