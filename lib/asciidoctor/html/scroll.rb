# frozen_string_literal: true

module Asciidoctor
  module Html
    # Due to mobile dynamic viewport heights, we need custom code for
    # reliable anchor scrolling.
    module Scroll
      SCROLL = <<~JS
        (function() {
          let scrolledOnce = false;
          const page = document.getElementById('page');
          function scrollToElement(e) {
            if(page.classList.contains('multi')) return;

            e && e.preventDefault();
            scrolledOnce = true;
            const href = location.hash;
            const id = href.substring(1);
            const target = document.getElementById(id);
            if(!target) return;

            const rect = target.getBoundingClientRect();
            page.scrollTo({
              top: rect.top + page.scrollTop,
              left: 0
            });
          }
          addEventListener('load', function() {
            !scrolledOnce && scrollToElement();
          });
          addEventListener('hashchange', scrollToElement);
          const clickableHSelector = [ 'h2', 'h3', 'h4' ].map(v => `section[id] > ${v}`).join(', ');
          document.querySelectorAll(clickableHSelector).forEach(el => {
            el.addEventListener('click', function() {
              location.hash = el.parentElement.id;
            });
          });
        })();
      JS
    end
  end
end
