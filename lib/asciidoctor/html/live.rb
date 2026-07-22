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
          selectBlock();

          const observer = new MutationObserver(() => {
            liveBlocks = container.querySelectorAll(liveBlocksSelector);
            liveBlockIdx = 0;
            selectBlock();
          });

          function selectBlock() {
            liveBlocks.forEach((block, idx) => {
              block.closest('.live-wrapper').firstElementChild.classList.toggle('selected', idx === liveBlockIdx);
            });
          }

          function getLines(block, lineNumber = -1, selected) {
            let selector = '[data-line-number]';
            if(lineNumber > -1) selector = `[data-line-number="${lineNumber}"]`;
            if(selected === false) selector += ':not(.emph)';
            if(selected === true) selector += '.emph';
            return block.querySelectorAll(selector);
          }

          function getNextLines() {
            while(liveBlocks.length > 0 && liveBlockIdx < liveBlocks.length) {
              selectBlock();
              const currentBlock = liveBlocks[liveBlockIdx];
              if(currentBlock) {
                toggleDefault(currentBlock);
                let lines = getLines(currentBlock, -1, true);
                if(lines.length > 0) {
                  const lineNumber = parseInt(lines[lines.length - 1].dataset.lineNumber) + 1;
                  lines = getLines(currentBlock, lineNumber);
                  if(lines.length > 0) return lines;
                } else {
                  lines = getLines(currentBlock, -1, false);
                  if(lines.length > 0) return getLines(currentBlock, lines[0].dataset.lineNumber);
                }
              }
              liveBlockIdx++;
            }
            ADHT.move('right');
            return [];
          }

          function nextBlock() {
            if(liveBlockIdx < liveBlocks.length - 1) {
              liveBlockIdx++;
              selectBlock();
            } else {
              ADHT.move('right');
            }
          }

          function prevBlock() {
            if(liveBlockIdx > 0) {
              liveBlockIdx--;
              selectBlock();
            } else {
              ADHT.move('left');
            }
          }

          function getPrevLines() {
            while(liveBlocks.length > 0 && liveBlockIdx > -1) {
              selectBlock();
              const currentBlock = liveBlocks[liveBlockIdx];
              if(currentBlock) {
                const lines = getLines(currentBlock, -1, true);
                if(lines.length > 0) {
                  const line = lines[lines.length - 1];
                  return getLines(currentBlock, line.dataset.lineNumber);
                }
              }
              liveBlockIdx--;
            }
            ADHT.move('left');
            return [];
          }

          function toggleDefault(block, reset = false) {
            const token = block.dataset.reset;
            if(reset) {
              block.classList.add(token);
              getLines(block).forEach(el => el.classList.remove('emph'));
            } else {
              block.classList.remove(token);
            }
          }

          observer.observe(container, { attributes: true, attributeFilter: ['data-flip'] });
          addEventListener('keyup', function(e) {
            if(!page.classList.contains('presentation')) return;

            const currentBlock = liveBlocks[liveBlockIdx];
            if(/^\\d$/.test(e.key)) {
              toggleDefault(currentBlock);
              const key = e.key === "0" ? "10" : e.key;
              getLines(currentBlock, e.key).forEach(el => el.classList.toggle('emph'));
            } else {
              switch(e.key) {
                case 'r':
                  toggleDefault(currentBlock, true);
                  break;
                case 'R':
                  liveBlocks.forEach(block => toggleDefault(block, true));
                  break;
                case 'n':
                  getNextLines().forEach(el => el.classList.add('emph'));
                  break;
                case 'b':
                  getPrevLines().forEach(el => el.classList.remove('emph'));
                  break;
                case 'N':
                  nextBlock();
                  break;
                case 'B':
                  prevBlock();
                  break;
              }
            }
          });
        })();
      JS
    end
  end
end
