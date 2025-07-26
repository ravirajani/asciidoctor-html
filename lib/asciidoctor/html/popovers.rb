# frozen_string_literal: true

module Asciidoctor
  module Html
    # Configure the popovers for footnotes and citations.
    module Popovers
      FOOTNOTES = <<~JS
        function initFootnotes() {
          document.querySelectorAll(".btn-fnref[data-contentid]").forEach(btn => {
            const id = btn.dataset.contentid;
            const footnote = document.getElementById(id);
            if(footnote) {
              new bootstrap.Popover(btn, {
                content: footnote,
                html: true,
                sanitize: false
              });
            }
          });
        }
        MathJax = {
          startup: {
            pageReady: function() {
              return MathJax.startup.defaultPageReady().then(initFootnotes);
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

      INIT = "#{TOOLTIPS}\n#{FOOTNOTES}".freeze
    end
  end
end
