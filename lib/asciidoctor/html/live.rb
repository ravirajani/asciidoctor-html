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

          function toggleDefault(block, reset = false) {
            if(reset) {
              const token = block.dataset.resetDefault;
              token && block.classList.add(token);
              delete block.dataset.resetDefault;
            } else {
              block.classList.forEach(token => {
                if(token.startsWith('live-default-')) {
                  block.dataset.resetDefault = token;
                  block.classList.remove(token);
                }
              });
            }
          }

          observer.observe(container, { attributes: true, attributeFilter: ['data-flip'] });
          addEventListener('keyup', function(e) {
            if(!page.classList.contains('presentation') || liveBlocks.length == 0) return;

            const currentBlock = liveBlocks[liveBlockIdx];
            if(/^\\d$/.test(e.key)) {
              toggleDefault(currentBlock);
              currentBlock.querySelectorAll(`[data-line-number="${e.key}"]`).forEach(el => el.classList.toggle('emph'));
            }
          });
        })();
      JS
    end
  end
end
