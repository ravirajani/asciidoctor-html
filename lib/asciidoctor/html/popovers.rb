# frozen_string_literal: true

module Asciidoctor
  module Html
    # Configure the popovers for footnotes and citations.
    module Popovers
      POPOVERS = <<~JS
        (async function() {
          const popovers = []
          async function initPopovers() {
            for(const el of document.querySelectorAll('.btn-po[data-contentid]')) {
              const id = el.dataset.contentid;
              let content = document.getElementById(id);
              if(content) {
                if(content.tagName == 'A') {
                  // This is an anchor of a bibitem
                  const bibItem = content.parentElement.cloneNode(true);
                  bibItem.removeChild(bibItem.firstChild); // remove the anchor
                  content = bibItem.innerHTML;
                } else {
                  await MathJax.typesetPromise([content]);
                  content = content.cloneNode(true);
                }
                popovers.push(new bootstrap.Popover(el, {
                  content: content,
                  html: true,
                  sanitize: false
                }));
              }
            }
          }
          addEventListener('click', e => {
            const match = e.target.closest('.btn-po[aria-describedby],.popover');
            if(!match) {
              popovers.forEach(po => po.hide());
            }
          })

          await MathJax.startup.promise;
          await initPopovers();

          // Enable tooltips
          document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
            bootstrap.Tooltip.getOrCreateInstance(el);
          });
        })();
      JS
    end
  end
end
