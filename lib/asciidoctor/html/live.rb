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
              block.firstElementChild.classList.toggle('selected', idx === liveBlockIdx);
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

      def self.wrap_live(content, live_attr)
        return content unless live_attr

        /\A(?<default>normal|faded|covered)-(?<live>faded|covered)\Z/ =~ live_attr

        live_class = %(live-#{live || "faded"})
        default_class = %(live-default-#{default || "normal"})
        <<~HTML
          <div class="live #{default_class} #{live_class}" data-reset="#{default_class}">
          <div class="live-select">
            <svg xmlns="http://www.w3.org/2000/svg" class="live-icon" transform="scale(-1 1)" viewBox="0 0 512 512">
              <path d="M403.623 242.703 226.443 8.728c-7.34-9.693-21.153-11.606-30.845-4.258-9.701 7.34-11.607 21.16-4.266 30.861l23.85 31.484c-50.984 22.605-111.261 5.426-111.261 5.426 27.887 45.796 77.341 56.749 92.622 59.093-28.271 33.774-45.388 77.234-45.396 124.674.023 66.872 33.936 125.966 85.396 160.969l-45.211 59.693c-7.341 9.701-5.435 23.52 4.266 30.869 9.692 7.333 23.505 5.427 30.845-4.258v-.008l177.18-233.982c5.942-7.856 5.942-18.74 0-26.588m-207.08 64.681c-9.393 0-17.011-23.013-17.011-51.406 0-28.363 7.618-51.377 17.011-51.377s17.01 23.014 17.01 51.377c0 28.393-7.618 51.406-17.01 51.406m66.587 74.482a152.3 152.3 0 0 1-35.857-33.036c19.5-9.846 34.02-47.632 34.02-92.852 0-45.189-14.52-82.968-34.005-92.822a151.7 151.7 0 0 1 35.842-33.006l95.32 125.858z" fill="currentColor"/>
            </svg>
          </div>
          #{content}</div> <!-- .live -->
        HTML
      end
    end
  end
end
