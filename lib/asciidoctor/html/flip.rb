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

            //TODO: any in section link should show the section.
            document.querySelectorAll('.chaphead, .preamble').forEach(el => {
              el.classList.toggle('hidden', target);
            });

            document.querySelectorAll('.section').forEach(el => {
              el.classList.toggle('d-block', el == target);
            });
          }
          flip();
          addEventListener('hashchange', flip);
        })();
      JS
    end
  end
end
