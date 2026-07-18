# frozen_string_literal: true

module Asciidoctor
  module Html
    # Script for live presentations
    module Live
      LIVE = <<~JS
        (function() {
          const page = document.getElementById('page');
          const container = document.getElementById('content-container');
          const liveBlocksSelector = ':scope > .flip.d-block .live';

          let liveBlocks = container.querySelectorAll(liveBlocksSelector);
          let liveBlockIdx = 0;

          const observer = new MutationObserver(function() {
            liveBlocks = container.querySelectorAll(liveBlocksSelector);
            liveBlockIdx = 0;
          });

          observer.observe(container, { attributes: true, attributeFilter: ['data-flip'] });
          addEventListener('keyup', function(e) {
            if(!page.classList.contains('presentation')) return;

            // Find all displayed live blocks
          });
        })();
      JS
    end
  end
end
