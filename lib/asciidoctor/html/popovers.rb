# frozen_string_literal: true

module Asciidoctor
  module Html
    # Configure the popovers for footnotes and citations.
    module Popovers
      def self.init_all
        "#{init_footnotes}\n#{init_tooltips}"
      end

      def self.init_footnotes
        <<~JS
          function initFootnotes() {
            document.querySelectorAll(".footnoteref .btn-fnref[data-contentid]").forEach(btn => {
              id = btn.dataset.contentid;
              footnote = document.getElementById(id);
              if(footnote) {
                new bootstrap.Popover(btn, {
                  content: footnote.innerHTML,
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
      end

      def self.init_tooltips
        <<~JS
          // Only enable tooltips on images if not a touch screen device
          if(!touch) {
            document.querySelectorAll('img[data-bs-toggle="tooltip"]').forEach(el => {
              bootstrap.Tooltip.getOrCreateInstance(el);
            });
          }
        JS
      end
    end
  end
end
