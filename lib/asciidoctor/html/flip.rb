# frozen_string_literal: true

module Asciidoctor
  module Html
    # Flip when pagestyle=multipage
    module Flip
      FLIP = <<~JS
        (function() {
          const page = document.getElementById('page');
          function flip(e) {
            e && e.preventDefault();
            const href = location.hash;
            const id = href.substring(1);
            const target = document.getElementById(id);

            document.querySelectorAll('.content-container > .chaphead, .content-container > .preamble').forEach(el => {
              el.classList.toggle('hidden', target);
            });

            if(!target) return;

            const sect_selector = '.content-container > .section';
            const section = target.closest(sect_selector);

            document.querySelectorAll(sect_selector).forEach(el => {
              el.classList.toggle('d-block', el == section);
            });

            ADHT.nudgeMenuBtn();
          }
          flip();
          addEventListener('hashchange', flip);
        })();
      JS
    end
  end
end
