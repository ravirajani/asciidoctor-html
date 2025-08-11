# frozen_string_literal: true

module Asciidoctor
  module Html
    # Configure the popovers for footnotes and citations.
    module Popovers
      POPOVERS = <<~JS
        (function() {
          const popovers = []
          function initPopovers() {
            document.querySelectorAll('.btn-po[data-contentid]').forEach(el => {
              const id = el.dataset.contentid;
              let content = document.getElementById(id);
              if(content) {
                if(content.tagName == 'A') {
                  // This is an anchor of a bibitem
                  const bibItem = content.parentElement.cloneNode(true)
                  bibItem.removeChild(bibItem.firstChild) // remove the anchor
                  content = bibItem.innerHTML
                }
                popovers.push(new bootstrap.Popover(el, {
                  content: content,
                  html: true,
                  sanitize: false
                }));
              }
            });
          }
          addEventListener('click', e => {
            const match = e.target.closest('.btn-po[aria-describedby],.popover');
            if(!match) {
              popovers.forEach(po => po.hide());
            }
          })
          MathJax.startup.promise.then(initPopovers);
          addEventListener('load', function() {
            // Enable tooltips on images
            document.querySelectorAll('img[data-bs-toggle="tooltip"]').forEach(el => {
              bootstrap.Tooltip.getOrCreateInstance(el);
            });
          });
          // Enable tooltips on abbreviations
          document.querySelectorAll('abbr[data-bs-toggle="tooltip"]').forEach(el => {
            bootstrap.Tooltip.getOrCreateInstance(el);
          });
        })();
      JS
    end
  end
end
